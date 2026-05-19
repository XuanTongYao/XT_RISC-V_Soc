// 该模块为mtime和mtimecmp寄存器，访问时不会有跨时钟域时序惩罚
// mtime在读取期间不被保护，在软件上进行处理；在写入期间会保护，但没有补偿
// mtimecmp初始值未知，软件在使用前务必设置mtimecmp，写入时默认清空中断
//
// 寄存器布局
// 0-mtimel 1-mtimeh
// 2-mtimecmpl 3-mtimecmph
module SystemTimer
  import Utils_Pkg::sel_t;
(
    // 计时时钟必须比高速总线时钟慢两倍及以上
    input systemtimer_clk,
    // 总线接口
    xt_hbus32_if.port hb,

    output logic mtimer_int = 0
);
  wire [1:0] waddr = hb.waddr[1:0];

  logic time_update_tff = 0;
  always_ff @(posedge systemtimer_clk) time_update_tff <= !time_update_tff;

  wire time_update;
  OncePulse #(
      .DELAY(2)
  ) u_OncePulse (
      .clk  (hb.clk),
      .ctrl (time_update_tff),
      .pulse(time_update)
  );


  // 写入期间保护mtime寄存器的值
  logic [63:0] mtime = 0;
  always_ff @(posedge hb.clk) begin
    if (hb.sel.wen && !waddr[1]) begin
      if (waddr[0]) begin
        mtime[63:32] <= hb.wdata;
      end else begin
        mtime[31:0] <= hb.wdata;
      end
    end else if (time_update) begin
      mtime <= mtime + 64'd1;
    end
  end


  logic update_irq;
  logic [31:0] mtimecmp[2];  // 0-低位 1-高位
  wire time_ge_cmp = mtime >= {mtimecmp[1], mtimecmp[0]};
  always_ff @(posedge hb.clk) begin
    update_irq <= hb.sel.wen || time_update;

    if (hb.sel.wen && waddr[1]) begin
      // 写入比较寄存器默认清空中断
      mtimer_int <= 0;
      mtimecmp[waddr[0]] <= hb.wdata;
    end else if (update_irq) begin
      mtimer_int <= time_ge_cmp;
    end
  end


  always_ff @(posedge hb.clk) begin
    if (hb.sel.ren) begin
      unique case (hb.raddr[1:0])
        2'b00: hb.rdata <= mtime[31:0];
        2'b01: hb.rdata <= mtime[63:32];
        2'b10: hb.rdata <= mtimecmp[0];
        2'b11: hb.rdata <= mtimecmp[1];
      endcase
    end
  end

endmodule
