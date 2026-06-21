module ROM_Reg #(
    parameter int unsigned DEPTH = 16,
    parameter int unsigned WIDTH = 32,
    parameter bit [WIDTH-1:0] DATA[DEPTH] = '{default: '0},
    localparam int unsigned ADDR_WIDTH = $clog2(DEPTH)
) (
    input clk,
    input clk_en,
    input rst,
    input [ADDR_WIDTH-1:0] address,
    output logic [WIDTH-1:0] q  /* synthesis syn_romstyle = "logic" */
);

  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      q <= 0;
    end else if (clk_en) begin
      q <= DATA[address];
    end
  end

endmodule
