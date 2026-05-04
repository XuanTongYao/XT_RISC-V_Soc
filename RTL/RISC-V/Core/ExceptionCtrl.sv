// 现在好像mepc设置得正常了
module ExceptionCtrl
  import CSR_Pkg::*;
  import CoreConfig::*;
  import Exception_Pkg::*;
#(
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,
    input flush,
    input stall_n,
    input jump_pending,

    // 提交点(只关心指令执行前的一刻)
    input exception_t exception_commit,

    input [CFG.PC_LEN-1:0] resume_addr,

    // 自陷控制接口
    trap_if.controller trap,

    // 外部中断控制器
    int_source_if.hart mint
);

  wire raise = exception_commit.raise;  // 是否引发同步异常
  wire [USED_CODE_LEN-1:0] raise_code = exception_commit.code;  // 引发代码

  // 中断需要等本条指令执行完成后再处理
  // 在valid_int_req时已经通过冲刷流水线，防止在下一个指令执行前被异常打断
  logic ready_for_int;
  always_ff @(posedge clk, posedge rst) begin
    if (rst || ready_for_int) begin
      ready_for_int <= 0;
    end else if (stall_n) begin
      ready_for_int <= trap.valid_int_req;
    end
  end

  // 注意防止stall等待时清空流水线
  assign trap.valid_int_req = trap.any_int_come && trap.mstatus.mie && !raise && stall_n;
  assign trap.occurred = ready_for_int || raise;
  assign trap.new_mepc = resume_addr;

  logic [30:0] code;
  assign trap.new_mcause = {ready_for_int, code};
  // assign new_mtval  = 0;
  always_comb begin
    trap.jump_addr = {trap.mtvec.base, 2'b0};
    code = PadExceptionCode(raise_code);
    if (ready_for_int) begin
      // 优先级: 外部->软件->定时器，这和中断号的顺序不一样
      if (trap.mie.meie && trap.mip.meip) begin
        code = mint.custom_int_code;  // 外部中断控制器重定向
        // code = MACHINE_EXTERNAL_INT;
      end else if (trap.mie.msie && trap.mip.msip) begin
        code = MACHINE_SOFTWARE_INT;
      end else if (trap.mie.mtie && trap.mip.mtip) begin
        code = MACHINE_TIMER_INT;
      end
      if (trap.mtvec.mode == 2'b01) begin
        trap.jump_addr = {{trap.mtvec.base + code[29:0]}, 2'b0};
      end
    end
  end


endmodule
