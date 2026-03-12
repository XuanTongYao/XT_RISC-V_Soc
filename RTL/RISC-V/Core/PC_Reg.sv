module PC_Reg
  import CoreConfig::*;
#(
    parameter bit [XLEN-1:0] PC_RESET = 0
) (
    input clk,
    input rst_sync,
    input stall_n,
    input rvc,

    input        [31:0] jump_addr,
    input               jump,
    output logic [31:0] pc
);

  logic [2:0] pc_increase;
  always_comb begin
    if (rvc) begin
      pc_increase = 3'd2;
    end else begin
      pc_increase = 3'd4;
    end
  end

  always_ff @(posedge clk, posedge rst_sync) begin
    if (rst_sync) begin
      pc <= PC_RESET;
    end else if (jump) begin
      pc <= jump_addr;
    end else if (stall_n) begin
      pc <= pc + {29'b0, pc_increase};
    end
  end

endmodule
