// 寄存器布局
// 0 led
module LED_LBUS
  import XT_LBUS_Pkg::*;
#(
    parameter int LED_NUM = 8
) (
    input lb_clk,
    input lb_slave_t xt_lb,
    input wsel,
    output logic [LED_NUM-1:0] rdata,

    output logic [LED_NUM-1:0] led = {LED_NUM{1'b1}}
);

  always_ff @(posedge lb_clk) begin
    if (wsel) begin
      led <= xt_lb.wdata[LED_NUM-1:0];
    end
  end

  assign rdata = led;

endmodule
