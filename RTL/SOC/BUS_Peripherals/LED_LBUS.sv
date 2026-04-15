// 寄存器布局
// 0 led
module LED_LBUS #(
    parameter int LED_NUM = 8
) (
    xt_lbus_slave_if.port lb,
    output logic [LED_NUM-1:0] led = {LED_NUM{1'b1}}
);

  always_ff @(posedge lb.clk) begin
    if (lb.wen) begin
      led <= lb.wdata[LED_NUM-1:0];
    end
  end

  assign lb.rdata = 8'(led);

endmodule
