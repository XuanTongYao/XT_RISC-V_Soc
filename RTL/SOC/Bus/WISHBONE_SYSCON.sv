module WISHBONE_SYSCON (
    input clk,
    input rst,
    output logic wb_clk_o,
    output logic wb_rst_o
);

  assign wb_clk_o = clk;
  assign wb_rst_o = rst;

endmodule
