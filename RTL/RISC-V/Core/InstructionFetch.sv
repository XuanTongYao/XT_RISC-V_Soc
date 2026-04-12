//----------指令读取模块----------//
module InstructionFetch
  import Exception_Pkg::*;
  import CoreConfig::*;
(
    input [31:0] pc,
    // 与上层连线
    instruction_if.requestor core_inst_if,
    // 传递给IF_ID
    instruction_if.to_next if_inst,

    // 异常处理
    output exception_t exception_if
);

  assign core_inst_if.addr = pc;
  assign if_inst.addr = pc;
  assign if_inst.inst = core_inst_if.inst;
  assign exception_if.raise = 0;
  assign exception_if.code = 0;

endmodule
