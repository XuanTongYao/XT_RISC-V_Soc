module WISHBONE_SYSCON (
    input clk,
    input rst,
    wishbone_syscon_if.syscon wb
);

  assign wb.clk = clk;
  assign wb.rst = rst;

endmodule
