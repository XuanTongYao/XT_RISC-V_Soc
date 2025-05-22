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
    input wait_for_interrupt,

    // 来自异常/中断控制器
    input any_interrupt_come,
    input valid_interrupt_request,
    input exception_occurred,
    input [31:0] exception_jump_addr,

    // 输出
    output logic [31:0] jump_addr,
    output logic jump_en,
    output logic hold_flag,
    output logic stall_n,
    output logic clearing_pipeline,
    output logic instruction_retire
);


  //----------跳转指令控制----------//
  // TODO 核心停止和跳转的优先级谁更高？
  always_comb begin
    if (exception_occurred) begin
      jump_addr = exception_jump_addr;
    end else begin
      jump_addr = jump_addr_ex;
    end

    jump_en   = jump_en_ex || exception_occurred;
    hold_flag = jump_en || valid_interrupt_request;
  end

  //----------指令执行控制----------//
  // 指令退役: 指令正常被执行
  // 肯定不算异常跳转和冲刷流水线的NOP
  // 核心暂停且没跳转时也不算
  assign instruction_retire = !(clearing_pipeline || exception_occurred) && (jump_en || stall_n);
  logic [1:0] nop_cnt;
  assign clearing_pipeline = nop_cnt != 0;
  always_ff @(posedge clk) begin
    if (rst_sync) begin
      nop_cnt <= 0;
    end else if (hold_flag) begin
      nop_cnt <= 2'b10;
    end else if (nop_cnt != 0) begin
      nop_cnt <= nop_cnt - 1'b1;
    end
  end

  //----------核心暂停控制----------//
  wire waiting_int = wait_for_interrupt && !any_interrupt_come;
  wire has_stall_req = |stall_req;
  always_comb begin
    stall_n = !(has_stall_req || waiting_int);
  end


endmodule
