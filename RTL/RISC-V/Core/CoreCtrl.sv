module CoreCtrl
  import CoreConfig::*;
#(
    parameter int STALL_REQ_NUM = 1,
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,

    // 来自外部控制
    input [STALL_REQ_NUM-1:0] stall_req,

    // 来自指令执行模块
    input [31:0] jump_addr_ex,
    input jump_en_ex,
    input wfi,

    // 自陷控制接口
    trap_if.core_controller trap,
    // 调试控制接口
    debug_if.core debug,

    // 输出
    output logic [CFG.XLEN-1:0] jump_addr,
    output logic jump,
    output logic flush,
    output logic stall_n,
    output logic flushing_pipeline,
    output logic jump_pending,
    // output logic instruction_retire

    // 回归正常程序流的地址
    output logic [CFG.PC_LEN-1:0] resume_addr,
    instruction_if.from_prev id_ex_inst
);
  localparam int XLEN = CFG.XLEN;
  localparam int PC_ZEROS = CFG.PC_ZEROS;


  //----------跳转指令控制----------//
  // 核心停止和跳转的优先级谁更高？(目前不会出现这种情况)
  always_comb begin
    if (debug.resume) begin
      jump_addr = XLEN'(64'(debug.dpc) << PC_ZEROS);
    end else if (!debug.halt && !debug.halted && trap.occurred) begin
      jump_addr = trap.jump_addr;
    end else begin
      jump_addr = jump_addr_ex;
    end

    jump  = jump_en_ex || (!debug.halt && !debug.halted && trap.occurred) || debug.resume;
    flush = jump || trap.valid_int_req || debug.valid_haltreq;
  end

  //----------程序流控制----------//
  // 指令退役: 指令正常被执行(目前不打算判断，除非后期增加了minstret寄存器)
  // 肯定不算异常跳转和冲刷流水线的NOP
  // 核心暂停且没跳转时也不算
  // assign instruction_retire = !(flushing_pipeline || trap.occurred) && (jump || stall_n);
  logic [1:0] nop_cnt;
  assign flushing_pipeline = nop_cnt[1];
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      nop_cnt <= 0;
      jump_pending <= 0;
    end else if (flush) begin
      nop_cnt <= '1;
      if (jump) jump_pending <= 1;
    end else if (nop_cnt[1]) begin
      nop_cnt <= {nop_cnt[0], 1'b0};
      jump_pending <= nop_cnt[0];
    end
  end

  // 正常程序流最后一次跳转地址(不含自陷或调试器强制跳转)
  logic [CFG.PC_LEN-1:0] last_jump_addr;
  always_ff @(posedge clk) begin
    if (stall_n && jump_en_ex) last_jump_addr <= jump_addr_ex[XLEN-1:PC_ZEROS];
  end
  assign resume_addr = jump_pending ? last_jump_addr : id_ex_inst.addr[XLEN-1:PC_ZEROS];


  //----------核心暂停控制----------//
  wire waiting_int = wfi && !trap.any_int_come && !debug.bypass_wfi;
  wire any_stall_req = |stall_req;
  always_comb begin
    stall_n = !(any_stall_req || waiting_int || debug.halted);
  end


endmodule
