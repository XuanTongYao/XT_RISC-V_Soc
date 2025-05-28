// 该机器计时器没有跨时钟域
// 访问时不会有跨时钟域时序惩罚，其他的计时器不一定
// 读取期间不保护寄存器的值，在软件上进行处理
module SystemTimer
  import XT_BUS::*;
(
    // 计时时钟必须比高速总线时钟慢两倍以上
    input systemtimer_clk,
    // 与高速总线
    input hb_clk,
    input hb_slave_t xt_hb,
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


  // mtime在低位，mtimecmp在高位
  wire read_cmp = xt_hb.raddr[3];
  wire read_time = ~xt_hb.raddr[3];
  wire write_cmp = xt_hb.waddr[3];
  wire write_time = ~xt_hb.waddr[3];
  wire read_high = xt_hb.raddr[2];
  wire write_high = xt_hb.waddr[2];

  logic [31:0] mtime_l = 0;
  logic [31:0] mtime_h = 0;
  wire [32:0] next_mtime_l = mtime_l + 1'b1;
  wire carry = next_mtime_l[32];
  wire [31:0] next_mtime_h = mtime_h + carry;
  // 写入期间保护计时寄存器的值
  always_ff @(posedge hb_clk) begin
    if (sel.wen && write_time) begin
      if (write_high) begin
        mtime_h <= xt_hb.wdata;
      end else begin
        mtime_l <= xt_hb.wdata;
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
        mtimecmp_h <= xt_hb.wdata;
      end else begin
        mtimecmp_l <= xt_hb.wdata;
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
