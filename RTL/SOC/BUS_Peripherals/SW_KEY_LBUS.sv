module SW_KEY_LBUS
  import XT_BUS::*;
(
    input lb_clk,
    input lb_slave_t xt_lb,
    output logic [15:0] rdata,

    input [3:0] key_raw,
    input [2:0] sw_raw
);

  //----------开关----------//
  logic [2:0] switch_reg;
  always_ff @(posedge lb_clk) begin
    switch_reg <= sw_raw;
  end


  //----------按键----------//
  logic [3:0] key_reg;
  always_ff @(posedge lb_clk) begin
    key_reg <= key_raw;
  end

  //----------读取----------//
  always_comb begin
    if (MatchRLB(xt_lb, 8'd0)) begin
      rdata = {12'b0, ~key_reg};
    end else if (MatchRLB(xt_lb, 8'd2)) begin
      rdata = {13'b0, switch_reg};
    end else begin
      rdata = 0;
    end
  end


endmodule
