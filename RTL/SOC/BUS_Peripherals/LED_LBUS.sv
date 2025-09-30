module LED_LBUS
  import XT_LBUS_Pkg::*;
#(
    parameter int LED_NUM = 8
) (
    input lb_clk,
    input lb_slave_t xt_lb,
    output logic [LED_NUM-1:0] rdata,

    output logic [LED_NUM-1:0] led = {LED_NUM{1'b1}}
);

  always_ff @(posedge lb_clk) begin
    if (MatchWLB(xt_lb, 8'd20)) begin
      led <= xt_lb.wdata[LED_NUM-1:0];
    end
  end


  always_comb begin
    if (MatchRLB(xt_lb, 8'd20)) begin
      rdata = led;
    end else begin
      rdata = 0;
    end
  end

endmodule
