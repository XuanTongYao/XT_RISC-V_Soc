// 模块: RISC-V内核
// 功能: 处理器内核能够执行RISC-V指令集的指令
//       目前仅支持RV32I_zicsr指令集
// 版本: v0.3
// BUG修复记录:
//
// 作者: 姚萱彤
// <<< 参 数 >>> //
// INST_FETCH_REG:      读取指令时是否经过寄存器，将决定在IF_ID模块是否对指令延迟一个周期
// STALL_REQ_NUM:       暂停请求的数量
//
// <<< 端 口 >>> //
// clk:            时钟信号
// rst:            复位信号
// stall_req:      流水线暂停请求(适用于IO需要等待时)


// 必须要在EX阶段执行流水线暂停
module RISC_V_Core
  import CSR_Pkg::*;
  import CoreConfig::*;
  import Exception_Pkg::*;
#(
    parameter core_cfg_t CFG,
    parameter bit INST_FETCH_REG = 0,  // 读取指令时是否已经经过寄存器
    parameter int STALL_REQ_NUM = 1,  // 暂停请求的数量
    parameter bit [CFG.XLEN-1:0] PC_RESET = 0
) (
    input clk,
    input rst,
    input [STALL_REQ_NUM-1:0] stall_req,
    output logic core_stall_n,

    // 访问指令存储器
    instruction_if.requestor core_inst_if,
    // 直接访存接口
    memory_direct_if.master  memory,

    // 中断源与外部中断控制器
    int_source_if.hart mint,

    // 调试器接口
    dm_hart_minimal_if.hart dm_hart,
    dm_register_if.hart command0
);
  localparam int XLEN = CFG.XLEN;

  //----------核心控制器----------//
  wire [31:0] jump_addr;
  wire jump;
  wire flush;
  wire stall_n;
  wire flushing_pipeline;
  wire jump_pending;
  //   wire instruction_retire;

  // 回归正常程序流的地址
  wire [CFG.PC_LEN-1:0] resume_addr;
  assign core_stall_n = stall_n;
  assign core_inst_if.enable = stall_n;

  wire wfi;

  wire exception_t exception_commit;  // 提前声明

  // 调试控制器
  debug_if debug ();
  wire debug_override_csr, debug_override_gpr;
  reg_r_if #(.DATA_LEN(XLEN)) debug_read_gpr ();
  reg_w_if #(.DATA_LEN(XLEN)) debug_write_gpr ();
  csr_rw_if #(.DATA_LEN(XLEN)) debug_rw_csr ();
  DebugCtrl #(.CFG(CFG)) u_DebugCtrl (.*);


  //----------寄存器----------//
  // 整数寄存器
  reg_r_if #(.DATA_LEN(XLEN)) read_rs1 (), read_rs2 ();
  reg_w_if #(.DATA_LEN(XLEN)) write_rd ();
  CoreReg #(.CFG(CFG)) u_CoreReg (.*);

  // PC寄存器
  wire [31:0] pc;
  wire rvc = 0;
  // wire rvc;
  PC_Reg #(
      .CFG(CFG),
      .PC_RESET(PC_RESET)
  ) u_PC_Reg (
      .*
  );

  // 控制与状态寄存器+自陷控制
  csr_rw_if #(.DATA_LEN(XLEN)) csr_rw ();
  // 自陷控制接口
  trap_if #(
      .XLEN  (XLEN),
      .PC_LEN(CFG.PC_LEN)
  ) trap ();
  CSR #(CFG) u_CSR (
      .*,
      .rw(csr_rw)
  );

  //----------流水线----------//
  instruction_if #(.XLEN(XLEN)) if_inst (), if_id_inst (), id_ex_inst ();  // 指令传输
  exception_if if_exception (), id_exception ();  // 异常

  InstructionFetch u_InstructionFetch (.*);

  // 为了适应不同速度的指令存储器，可以选择指令是否打一拍
  IF_ID #(.INST_DELAY_1TICK(!INST_FETCH_REG)) u_IF_ID (.*);

  wire [31:0] next_execute_pc = if_id_inst.addr;
  id_to_ex_if #(.XLEN(XLEN)) id_out ();
  InstructionDecode #(.CFG(CFG)) u_InstructionDecode (.*);

  id_to_ex_if #(.XLEN(XLEN)) id_ex_out ();
  ID_EX u_ID_EX (.*);

  // 目前译码和执行不平衡（执行高占用），某些信号可以在Decode中提前提取
  wire [31:0] jump_addr_ex;
  wire jump_en_ex;
  InstructionExecute #(.CFG(CFG)) u_InstructionExecute (.*);


  ExceptionPipeLine u_ExceptionPipeLine (.*);

  // wire [31:0] new_mtval;
  ExceptionCtrl #(.CFG(CFG)) u_ExceptionCtrl (.*);
  CoreCtrl #(
      .STALL_REQ_NUM(STALL_REQ_NUM),
      .CFG(CFG)
  ) u_CoreCtrl (
      .*
  );

endmodule
