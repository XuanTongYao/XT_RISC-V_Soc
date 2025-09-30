// 该机器计时器没有跨时钟域
// 访问时不会有跨时钟域时序惩罚，其他的计时器不一定
// 读取期间不保护寄存器的值，在软件上进行处理
module SystemTimer
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
(
    // 计时时钟必须比高速总线时钟慢两倍以上
    input systemtimer_clk,
    // 与高速总线
    input hb_clk,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,

    output logic mtimer_int = 0
);

  wire time_update_pulse;
  OncePulse #(
      .TRIGGER(2'b01)
  ) u_OncePulse (
      .clk  (hb_clk),
      .ctrl (systemtimer_clk),
      .pulse(time_update_pulse)
  );


  // mtime在低位地址0、1，mtimecmp在高位地址2、3
  wire read_time = sys_share.raddr == 'd0 || sys_share.raddr == 'd1;
  wire read_cmp = sys_share.raddr == 'd2 || sys_share.raddr == 'd3;

  wire write_time = sys_share.waddr == 'd0 || sys_share.waddr == 'd1;
  wire write_cmp = sys_share.waddr == 'd2 || sys_share.waddr == 'd3;

  wire read_high = sys_share.raddr == 'd1 || sys_share.raddr == 'd3;
  wire write_high = sys_share.waddr == 'd1 || sys_share.waddr == 'd3;

  logic [31:0] mtime_l = 0;
  logic [31:0] mtime_h = 0;
  wire [32:0] next_mtime_l = mtime_l + 1'b1;
  wire carry = next_mtime_l[32];
  wire [31:0] next_mtime_h = mtime_h + carry;
  // 写入期间保护计时寄存器的值
  always_ff @(posedge hb_clk) begin
    if (sel.wen && write_time) begin
      if (write_high) begin
        mtime_h <= sys_share.wdata;
      end else begin
        mtime_l <= sys_share.wdata;
      end
    end else if (time_update_pulse) begin
      mtime_l <= next_mtime_l[31:0];
      mtime_h <= next_mtime_h;
    end
  end


  logic update_irq = 0;
  logic [31:0] mtimecmp_l = 0;
  logic [31:0] mtimecmp_h = 0;
  wire time_ge_cmp = {mtime_h, mtime_l} >= {mtimecmp_h, mtimecmp_l};
  always_ff @(posedge hb_clk) begin
    update_irq <= sel.wen || time_update_pulse;

    if (sel.wen && write_cmp) begin
      // 写入比较寄存器默认清空中断
      mtimer_int <= 0;
      if (write_high) begin
        mtimecmp_h <= sys_share.wdata;
      end else begin
        mtimecmp_l <= sys_share.wdata;
      end
    end else if (update_irq) begin
      mtimer_int <= time_ge_cmp;
    end
  end


  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      unique case ({
        read_cmp, read_high
      })
        2'b00: rdata <= mtime_l;
        2'b01: rdata <= mtime_h;
        2'b10: rdata <= mtimecmp_l;
        2'b11: rdata <= mtimecmp_h;
      endcase
    end
  end

endmodule
