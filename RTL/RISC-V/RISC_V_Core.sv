// 模块: RISC-V内核
// 功能: 处理器内核能够执行RISC-V指令集的指令
//       目前仅支持RV32I指令集
// 版本: v0.2
// BUG修复记录:
//
// 作者: 姚萱彤
// <<< 参 数 >>> //
// INST_FETCH_REG:      读取指令时是否经过寄存器，将决定在IF_ID模块是否对指令延迟一个周期
// STALL_REQ_NUM:       暂停请求的数量
//
// <<< 端 口 >>> //
// clk:            时钟信号
// rst_sync:       同步复位信号
// stall_req:      流水线暂停请求(适用于IO需要等待时)


// 必须要在EX阶段执行流水线暂停
module RISC_V_Core #(
    parameter bit INST_FETCH_REG = 0,  // 读取指令时是否已经经过寄存器
    parameter int STALL_REQ_NUM  = 1   // 暂停请求的数量
) (
    input clk,
    input rst_sync,
    input [STALL_REQ_NUM-1:0] stall_req,
    output logic core_stall_n,

    // 访问指令存储器
    input [31:0] instruction,
    output logic [31:0] instruction_addr,

    // 与高速总线相连
    output logic access_ram_read,
    output logic access_ram_write,
    output logic [1:0] access_ram_write_width,  // 写入的大小 字节、半字、字
    output logic [31:0] access_ram_raddr,
    output logic [31:0] access_ram_waddr,
    input [31:0] access_ram_rdata,
    output logic [31:0] access_ram_wdata,

    // 访问中断控制器
    input mextern_int,
    input msoftware_int,
    input mtimer_int,
    input [30:0] mextern_int_id,

    // Debug
    output logic [31:0] instruction_addr_id_ex_debug
);
  import CSR_Typedefs::*;

  //----------核心控制器----------//
  wire [31:0] jump_addr;
  wire jump_en;
  wire hold_flag;
  wire stall_n;
  wire clearing_pipeline;
  wire instruction_retire;
  assign core_stall_n = stall_n;

  wire wait_for_interrupt;



  //----------寄存器----------//
  // 整数寄存器
  wire [4:0] reg1_raddr;
  wire [4:0] reg2_raddr;
  wire [31:0] reg1_rdata;
  wire [31:0] reg2_rdata;

  wire reg_wen;
  wire [4:0] reg_waddr;
  wire [31:0] reg_wdata;

  // PC寄存器
  wire [31:0] pc;
  wire [31:0] next_pc;
  PC_Reg u_PC_Reg (.*);

  // 控制状态寄存器
  wire exception_returned;
  wire csr_r_en;
  wire csr_w_en;
  wire [11:0] csr_rwaddr;
  wire [31:0] csr_wdata;

  wire mstatus_t csr_mstatus;
  wire mie_t csr_mie;
  wire mip_t csr_mip;
  wire [31:0] csr_mtvec;
  wire [31:0] csr_mepc;
  wire [31:0] csr_rdata;


  //----------流水线----------//

  wire [31:0] instruction_addr_if;
  wire [31:0] instruction_if;
  wire exception_if;
  wire [3:0] exception_cause_if;
  InstructionFetch u_InstructionFetch (.*);


  wire [31:0] instruction_addr_if_id;
  wire [31:0] instruction_if_id;
  // 为了适应不同速度的指令存储器，可以选择指令是否打一拍
  IF_ID #(.INST_DELAY_1TICK(!INST_FETCH_REG)) u_IF_ID (.*);


  wire [31:0] instruction_addr_id;
  wire [31:0] instruction_id;
  wire [31:0] operand1_id;
  wire [31:0] operand2_id;
  wire reg_wen_id;
  wire exception_id;
  wire [3:0] exception_cause_id;
  wire ram_load_access_id;
  wire [31:0] ram_load_addr_id;
  assign next_pc = instruction_addr_id;
  InstructionDecoder u_InstructionDecoder (
      // 来自IF_ID
      .*,
      // 与寄存器
      .reg_src1_addr(reg1_raddr),
      .reg_src2_addr(reg2_raddr),
      .reg_src1_data(reg1_rdata),
      .reg_src2_data(reg2_rdata)
      // 传递给ID_EX
  );

  wire        ram_load_access_id_ex;
  wire [31:0] ram_load_addr_id_ex;
  wire [31:0] instruction_addr_id_ex;
  wire [31:0] instruction_id_ex;
  wire [31:0] operand1;
  wire [31:0] operand2;
  wire        reg_wen_id_ex;
  ID_EX u_ID_EX (.*);

  assign instruction_addr_id_ex_debug = instruction_addr_id_ex;

  // 目前译码和执行不平衡（执行高占用），某些信号可以在Decode中提前提取
  wire [31:0] jump_addr_ex;
  wire jump_en_ex;
  InstructionExecute u_InstructionExecute (
      // 来自ID_EX
      .*,
      // 传递给寄存器
      .reg_wen_out    (reg_wen),
      // 访存
      .ram_load_en    (access_ram_read),
      .ram_load_addr  (access_ram_raddr),
      .ram_load_data  (access_ram_rdata),
      .ram_store_en   (access_ram_write),
      .ram_store_width(access_ram_write_width),
      .ram_store_addr (access_ram_waddr),
      .ram_store_data (access_ram_wdata)
  );


  wire [31:0] new_mepc;
  wire [31:0] new_mcause;
  wire [31:0] new_mtval;
  wire any_interrupt_come;
  wire valid_interrupt_request;
  wire exception_occurred;
  wire [31:0] exception_jump_addr;
  ExceptionCtrl u_ExceptionCtrl (.*);
  CoreCtrl #(.STALL_REQ_NUM(STALL_REQ_NUM)) u_CoreCtrl (.*);


  //----------寄存器单元----------//
  CoreReg u_CoreReg (.*);
  CSR u_CSR (.*);

endmodule
