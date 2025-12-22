// 现在好像mepc设置得正常了
module ExceptionCtrl
  import CSR_Pkg::*;
  import CoreConfig::*;
  import Exception_Pkg::*;
(
    input clk,
    input rst_sync,
    input flush,
    input stall_n,
    input jump_pending,

    // 提交点(只关心指令执行前的一刻)
    input exception_t exception_commit,

    input [PC_LEN-1:0] instruction_addr_id_ex,
    input [PC_LEN-1:0] jump_addr_ex,
    input jump_en_ex,

    // 访问CSR
    input mstatus_t csr_mstatus,
    input mie_m_only_t csr_mie,
    input mip_m_only_t csr_mip,
    input mtvec_t csr_mtvec,
    output logic [PC_LEN-1:0] new_mepc,
    output mcause_t new_mcause,
    // output logic [31:0] new_mtval,

    output logic any_int_come,
    output logic valid_int_req,
    output logic trap_occurred,
    output logic [31:0] trap_jump_addr,

    // 外部中断控制器
    input [30:0] custom_int_code
);

  wire raise = exception_commit.raise;  // 是否引发同步异常
  wire [USED_CODE_LEN-1:0] raise_code = exception_commit.code;  // 引发代码

  // 中断需要等本条指令执行完成后再处理
  // 在valid_int_req时已经通过冲刷流水线，防止在下一个指令执行前被异常打断
  logic ready_for_int;
  logic [PC_LEN-1:0] last_jump_addr;
  always_ff @(posedge clk) begin
    if (rst_sync || ready_for_int) begin
      ready_for_int <= 0;
    end else if (stall_n) begin
      ready_for_int <= valid_int_req;
      if (jump_en_ex) last_jump_addr <= jump_addr_ex;
    end
  end

  wire is_int = !raise && csr_mstatus.mie;
  assign any_int_come = (csr_mie & csr_mip) != 0;
  assign valid_int_req = any_int_come && is_int && stall_n;  // 注意防止stall等待时清空流水线
  assign trap_occurred = ready_for_int || raise;
  assign new_mepc = jump_pending ? last_jump_addr : instruction_addr_id_ex;

  logic [30:0] code;
  assign new_mcause = {is_int, code};
  // assign new_mtval  = 0;
  always_comb begin
    trap_jump_addr = {csr_mtvec.base, 2'b0};
    code = PadExceptionCode(raise_code);
    if (is_int) begin
      // 优先级: 外部->软件->定时器，这和中断号的顺序不一样
      if (csr_mie.meie && csr_mip.meip) begin
        code = custom_int_code;  // 外部中断控制器重定向
        // code = MACHINE_EXTERNAL_INT;
      end else if (csr_mie.msie && csr_mip.msip) begin
        code = MACHINE_SOFTWARE_INT;
      end else if (csr_mie.mtie && csr_mip.mtip) begin
        code = MACHINE_TIMER_INT;
      end
      if (csr_mtvec.mode == 2'b01) begin
        trap_jump_addr = {{csr_mtvec.base + code[29:0]}, 2'b0};
      end
    end
  end


endmodule
