module PC_Reg #(
    parameter bit RVC_SUPPORT = 0
) (
    input clk,
    input rst_sync,
    input stall_n,

    input        [31:0] jump_addr,
    input               jump,
    output logic [31:0] pc
);

  always_ff @(posedge clk) begin
    if (rst_sync) begin
      pc <= 0;
    end else if (jump) begin
      pc <= jump_addr;
    end else if (stall_n) begin
      pc <= pc + 3'd4;
    end
  end

endmodule
