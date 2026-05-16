// 该模块为mtime和mtimecmp寄存器，访问时不会有跨时钟域时序惩罚
// mtime在读取期间不被保护，在软件上进行处理；在写入期间会保护，但没有补偿
// mtimecmp初始值未知，软件在使用前务必设置mtimecmp，写入时默认清空中断
//
// 寄存器布局
// 0-mtimel 1-mtimeh
// 2-mtimecmpl 3-mtimecmph
module SystemTimer
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
(
    // 计时时钟必须比高速总线时钟慢两倍及以上
    input systemtimer_clk,
    // 与高速总线
    input hb_clk,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,

    output logic mtimer_int = 0
);
  wire [1:0] waddr = sys_share.waddr[1:0];

  logic time_update_tff = 0;
  always_ff @(posedge systemtimer_clk) time_update_tff <= !time_update_tff;

  wire time_update;
  OncePulse #(
      .DELAY(2)
  ) u_OncePulse (
      .clk  (hb_clk),
      .ctrl (time_update_tff),
      .pulse(time_update)
  );


  // 写入期间保护mtime寄存器的值
  logic [63:0] mtime = 0;
  always_ff @(posedge hb_clk) begin
    if (sel.wen && !waddr[1]) begin
      if (waddr[0]) begin
        mtime[63:32] <= sys_share.wdata;
      end else begin
        mtime[31:0] <= sys_share.wdata;
      end
    end else if (time_update) begin
      mtime <= mtime + 64'd1;
    end
  end


  logic update_irq;
  logic [31:0] mtimecmp[2];  // 0-低位 1-高位
  wire time_ge_cmp = mtime >= {mtimecmp[1], mtimecmp[0]};
  always_ff @(posedge hb_clk) begin
    update_irq <= sel.wen || time_update;

    if (sel.wen && waddr[1]) begin
      // 写入比较寄存器默认清空中断
      mtimer_int <= 0;
      mtimecmp[waddr[0]] <= sys_share.wdata;
    end else if (update_irq) begin
      mtimer_int <= time_ge_cmp;
    end
  end


  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      unique case (sys_share.raddr[1:0])
        2'b00: rdata <= mtime[31:0];
        2'b01: rdata <= mtime[63:32];
        2'b10: rdata <= mtimecmp[0];
        2'b11: rdata <= mtimecmp[1];
      endcase
    end
  end

endmodule
