module WISHBONE_SYSCON (
    input clk,
    input rst_sync,
    output logic wb_clk_o,
    output logic wb_rst_o
);

  assign wb_clk_o = clk;

  always_ff @(posedge clk) begin
    wb_rst_o <= rst_sync;
  end

endmodule
