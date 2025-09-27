//----------指令读取模块----------//
module InstructionFetch
  import Exception_Pkg::*;
(
    input [31:0] pc,
    // 与上层连线
    output logic [31:0] instruction_addr,
    input [31:0] instruction,
    // 传递给IF_ID
    output logic [31:0] instruction_addr_if,
    output logic [31:0] instruction_if,

    // 异常处理
    output exception_t exception_if
);

  assign instruction_addr_if = pc;
  assign instruction_addr = pc;
  assign instruction_if = instruction;
  assign exception_if.raise = 0;
  assign exception_if.code = 0;

endmodule
