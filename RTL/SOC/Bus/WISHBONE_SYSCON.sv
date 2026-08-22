module WISHBONE_SYSCON (
    input clk,
    input rst,
    wishbone_syscon_if.syscon wb_sys
);

  assign wb_sys.clk = clk;
  assign wb_sys.rst = rst;

endmodule
