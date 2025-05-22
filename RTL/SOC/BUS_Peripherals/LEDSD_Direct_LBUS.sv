module LEDSD_Direct_LBUS
  import XT_BUS::*;
#(
    parameter bit E_CODE = 0,
    parameter bit COM = 0,
    parameter int NUM = 2
) (
    input lb_clk,
    input lb_slave_t xt_lb,
    output logic [7:0] rdata,

    output logic [8:0] ledsd[NUM]
);

  typedef struct packed {
    logic [NUM-1:0] dig;
    logic [NUM-1:0] dp;
  } ledsd_control_t;
  ledsd_control_t ledsd_control;

  logic [7:0] display_data;
  always_ff @(posedge lb_clk) begin
    if (MatchWLB(xt_lb, 8'd21)) begin
      display_data <= xt_lb.wdata[7:0];
    end else if (MatchWLB(xt_lb, 8'd22)) begin
      ledsd_control <= xt_lb.wdata[(2*NUM)-1:0];
    end
  end


  always_comb begin
    if (MatchRLB(xt_lb, 8'd21)) begin
      rdata = display_data;
    end else if (MatchRLB(xt_lb, 8'd22)) begin
      rdata = {{(8 - (2 * NUM)) {1'b0}}, ledsd_control};
    end else begin
      rdata = 0;
    end
  end


  LEDSD_Direct #(
      .E_CODE(E_CODE),
      .COM   (COM),
      .NUM   (NUM)
  ) u_LEDSD_Direct (
      .data_in({display_data}),
      .dig    ({ledsd_control.dig}),
      .dp     ({ledsd_control.dp}),
      .ledsd  (ledsd)
  );

endmodule
