`include "../../Defines/InstructionDefines.sv"
// 数据停一个时钟周期可选
module IF_ID #(
    parameter bit INST_DELAY_1TICK = 1
) (
    input clk,
    input rst_sync,
    input hold_flag,
    input stall_n,

    // 中间传递
    input [31:0] instruction_addr_if,
    input [31:0] instruction_if,
    input        exception_if,

    output logic [31:0] instruction_addr_if_id,
    output logic [31:0] instruction_if_id
);

  // 指令地址一定会停一个周期
  // 都是NOP指令了，指令地址 不需要清零，对处理异常也有好处
  always_ff @(posedge clk) begin
    if (stall_n) begin
      instruction_addr_if_id <= instruction_addr_if;
    end
  end

  generate
    if (INST_DELAY_1TICK) begin : gen_delay_1tick
      always_ff @(posedge clk) begin
        if (rst_sync || hold_flag || exception_if) begin
          instruction_if_id <= `INST_NOP;
        end else if (stall_n) begin
          instruction_if_id <= instruction_if;
        end
      end
    end else begin : gen_none_delay
      logic clear;
      always_ff @(posedge clk) begin
        clear <= rst_sync || hold_flag || exception_if;
      end
      assign instruction_if_id = clear ? `INST_NOP : instruction_if;
    end
  endgenerate



endmodule
