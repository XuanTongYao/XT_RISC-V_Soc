module SyncAsyncReset #(
    parameter int PERIOD = 1  // 复位持续时间
) (
    input clk,
    input rst_i_n,
    output logic rst_o_n
);

  logic [PERIOD:0] reset_reg;  // PERIOD+1个寄存器
  always_ff @(posedge clk, negedge rst_i_n) begin
    if (!rst_i_n) begin
      reset_reg <= 0;
    end else begin
      reset_reg[0] <= 1'b1;
      reset_reg[PERIOD:1] <= reset_reg[PERIOD-1:0];
    end
  end

  assign rst_o_n = reset_reg[PERIOD];


endmodule
