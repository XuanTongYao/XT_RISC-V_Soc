module CoreCtrl #(
    parameter int STALL_REQ_NUM = 1
) (
    input clk,
    input rst_sync,

    // 来自外部控制
    input [STALL_REQ_NUM-1:0] stall_req,

    // 来自指令执行模块
    input [31:0] jump_addr_ex,
    input jump_en_ex,
    input wfi,

    // 来自异常/中断控制器
    input any_int_come,
    input valid_int_req,
    input trap_occurred,
    input [31:0] trap_jump_addr,

    // 输出
    output logic [31:0] jump_addr,
    output logic jump,
    output logic flush,
    output logic stall_n,
    output logic flushing_pipeline,
    output logic jump_pending,
    output logic instruction_retire
);


  //----------跳转指令控制----------//
  // 核心停止和跳转的优先级谁更高？(目前不会出现这种情况)
  always_comb begin
    if (trap_occurred) begin
      jump_addr = trap_jump_addr;
    end else begin
      jump_addr = jump_addr_ex;
    end

    jump  = jump_en_ex || trap_occurred;
    flush = jump || valid_int_req;
  end

  //----------指令执行控制----------//
  // 指令退役: 指令正常被执行
  // 肯定不算异常跳转和冲刷流水线的NOP
  // 核心暂停且没跳转时也不算
  assign instruction_retire = !(flushing_pipeline || trap_occurred) && (jump || stall_n);
  logic [1:0] nop_cnt;
  assign flushing_pipeline = nop_cnt != 0;
  always_ff @(posedge clk, posedge rst_sync) begin
    if (rst_sync) begin
      nop_cnt <= 0;
      jump_pending <= 0;
    end else if (flush) begin
      nop_cnt <= 2'b11;
      if (jump) jump_pending <= 1'b1;
    end else if (nop_cnt != 0) begin
      nop_cnt <= {nop_cnt[0], 1'b0};
      jump_pending <= nop_cnt[0];
    end
  end

  //----------核心暂停控制----------//
  wire waiting_int = wfi && !any_int_come;
  wire any_stall_req = |stall_req;
  always_comb begin
    stall_n = !(any_stall_req || waiting_int);
  end


endmodule
