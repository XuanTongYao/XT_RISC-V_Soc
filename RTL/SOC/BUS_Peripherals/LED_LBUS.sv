// 寄存器布局
// 0 led
module LED_LBUS #(
    parameter int LED_COUNT = 8
) (
    xt_lbus_if.port lb,
    output logic [LED_COUNT-1:0] led = '1
);

  always_ff @(posedge lb.clk) begin
    if (lb.wen) begin
      led <= lb.wdata[LED_COUNT-1:0];
    end
  end

  assign lb.rdata = 32'(led);

endmodule
