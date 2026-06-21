module ROM #(
    parameter int unsigned DEPTH = 16,
    parameter int unsigned WIDTH = 32,
    parameter bit [WIDTH-1:0] DATA[DEPTH] = '{default: '0},
    localparam int unsigned ADDR_WIDTH = $clog2(DEPTH)
) (
    input [ADDR_WIDTH-1:0] address,
    output logic [WIDTH-1:0] q  /* synthesis syn_romstyle = "logic" */
);
  assign q = DATA[address];
endmodule
