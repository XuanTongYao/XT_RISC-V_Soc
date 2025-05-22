//----------指令读取模块----------//
module InstructionFetch (
    input [31:0] pc,
    // 与上层连线
    output logic [31:0] instruction_addr,
    input [31:0] instruction,
    // 传递给IF_ID
    output logic [31:0] instruction_addr_if,
    output logic [31:0] instruction_if,

    // 异常处理
    output logic exception_if,
    output logic [3:0] exception_cause_if
);

  assign instruction_addr_if = pc;
  assign instruction_addr = pc;
  assign instruction_if = instruction;
  assign exception_if = 0;
  assign exception_cause_if = 0;

endmodule
