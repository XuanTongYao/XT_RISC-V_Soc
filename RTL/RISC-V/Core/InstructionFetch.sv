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
    exception_if.source if_exception
);

  assign core_inst_if.addr = pc;
  assign if_inst.addr = pc;
  assign if_inst.inst = core_inst_if.inst;
  assign if_exception.raise = 0;
  assign if_exception.code = 0;

endmodule
