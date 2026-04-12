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

    // 与高速总线相连
    output logic access_ram_read,
    output logic access_ram_write,
    output logic [1:0] access_ram_width,  // 访问的大小 字节、半字、字
    output logic [31:0] access_ram_raddr,
    output logic [31:0] access_ram_waddr,
    input [31:0] access_ram_rdata,
    output logic [31:0] access_ram_wdata,

    // 访问中断控制器
    input mextern_int,
    input msoftware_int,
    input mtimer_int,
    input [30:0] custom_int_code
);


  //----------核心控制器----------//
  wire [31:0] jump_addr;
  wire jump;
  wire flush;
  wire stall_n;
  wire flushing_pipeline;
  wire jump_pending;
  wire instruction_retire;
  assign core_stall_n = stall_n;

  wire wfi;



  //----------寄存器----------//
  // 整数寄存器
  wire reg_wen;
  wire [4:0] reg1_raddr, reg2_raddr, reg_waddr;
  wire [CFG.XLEN-1:0] reg1_rdata, reg2_rdata, reg_wdata;
  CoreReg #(.CFG(CFG)) u_CoreReg (.*);

  // PC寄存器
  wire [31:0] pc;
  wire [31:0] next_pc;
  wire rvc = 0;
  // wire rvc;
  PC_Reg #(
      .CFG(CFG),
      .PC_RESET(PC_RESET)
  ) u_PC_Reg (
      .*
  );

  // 控制状态寄存器
  wire trap_returned;
  wire csr_ren;
  wire csr_wen;
  wire [11:0] csr_rwaddr;
  wire [31:0] csr_wdata;

  wire mstatus_t csr_mstatus;
  wire mie_m_only_t csr_mie;
  wire mip_m_only_t csr_mip;
  wire mtvec_t csr_mtvec;
  wire [CFG.PC_LEN-1:0] csr_mepc;
  wire [31:0] csr_rdata;


  //----------流水线----------//
  instruction_if if_inst ();
  wire exception_t exception_if;
  wire exception_if_raise = exception_if.raise;
  InstructionFetch u_InstructionFetch (.*);


  instruction_if if_id_inst ();
  // 为了适应不同速度的指令存储器，可以选择指令是否打一拍
  IF_ID #(.INST_DELAY_1TICK(!INST_FETCH_REG)) u_IF_ID (.*);


  wire ram_store_access_id, ram_load_access_id;
  wire [31:0] ram_load_addr_id, ram_store_addr_id;
  wire [31:0] ram_store_data_id;
  wire [31:0] operand1_id, operand2_id;
  wire reg_wen_id;
  wire exception_t exception_id;
  wire exception_id_raise = exception_id.raise;
  assign next_pc = if_id_inst.addr;
  InstructionDecode #(.CFG(CFG)) u_InstructionDecode (.*);

  instruction_if id_ex_inst ();
  wire ram_store_access_id_ex, ram_load_access_id_ex;
  wire [31:0] ram_load_addr_id_ex, ram_store_addr_id_ex;
  wire [31:0] ram_store_data_id_ex;
  wire [31:0] operand1, operand2;
  wire reg_wen_id_ex;
  ID_EX u_ID_EX (.*);


  // 目前译码和执行不平衡（执行高占用），某些信号可以在Decode中提前提取
  wire [31:0] jump_addr_ex;
  wire jump_en_ex;
  InstructionExecute #(
      .CFG(CFG)
  ) u_InstructionExecute (
      .*,
      // 访存
      .ram_load_en     (access_ram_read),
      .ram_load_addr   (access_ram_raddr),
      .ram_load_data   (access_ram_rdata),
      .ram_store_en    (access_ram_write),
      .ram_store_addr  (access_ram_waddr),
      .ram_store_data  (access_ram_wdata),
      .ram_access_width(access_ram_width)
  );


  wire exception_t exception_commit;
  ExceptionPipeLine u_ExceptionPipeLine (.*);

  wire [CFG.PC_LEN-1:0] new_mepc;
  wire mcause_t new_mcause;
  // wire [31:0] new_mtval;
  wire any_int_come;
  wire valid_int_req;
  wire trap_occurred;
  wire [31:0] trap_jump_addr;
  ExceptionCtrl #(
      .CFG(CFG)
  ) u_ExceptionCtrl (
      .*,
      .instruction_addr_id_ex(id_ex_inst.addr[CFG.XLEN-1:CFG.PC_ZEROS]),
      .jump_addr_ex(jump_addr_ex[CFG.XLEN-1:CFG.PC_ZEROS])
  );
  CoreCtrl #(.STALL_REQ_NUM(STALL_REQ_NUM)) u_CoreCtrl (.*);
  CSR #(CFG) u_CSR (.*);  // 控制与状态寄存器

endmodule
