// 现在好像mepc设置得正常了
import CSR_Typedefs::*;
module ExceptionCtrl (
    input clk,
    input rst_sync,
    input flush,
    input stall_n,


    //异常源
    input exception_if,
    input exception_id,
    input [3:0] exception_cause_if,
    input [3:0] exception_cause_id,

    input [31:0] instruction_addr_id_ex,
    input [31:0] jump_addr_ex,
    input jump_en_ex,

    // 访问CSR
    input mstatus_t csr_mstatus,
    input mie_t csr_mie,
    input mip_t csr_mip,
    input [31:0] csr_mtvec,
    output logic [31:0] new_mepc,
    output logic [31:0] new_mcause,
    output logic [31:0] new_mtval,

    output logic any_interrupt_come,
    output logic valid_interrupt_request,
    output logic exception_occurred,
    output logic [31:0] exception_jump_addr,

    // 外部中断控制器
    input [30:0] mextern_int_id
);

  //----------异常流水线----------//
  typedef struct packed {
    logic occurred;
    logic [3:0] cause;
  } exception_cause_t;
  exception_cause_t exc_cause_if_id = {1'b0, 4'b0};
  exception_cause_t exc_cause_id_ex = {1'b0, 4'b0};
  always_ff @(posedge clk) begin
    if (rst_sync || flush) begin
      exc_cause_if_id <= 0;
      exc_cause_id_ex <= 0;
    end else if (stall_n) begin
      exc_cause_if_id <= {exception_if, exception_cause_if};
      if (exception_id) begin
        exc_cause_id_ex <= {exception_id, exception_cause_id};
      end else begin
        exc_cause_id_ex <= exc_cause_if_id;
      end
    end
  end

  //----------异常/中断处理----------//
  // 中断需要等本条指令执行完成后再处理
  // 在valid_interrupt_request时已经通过冲刷流水线，防止在下一个指令执行前被异常打断
  logic ready_interrupt;
  logic [31:0] last_jump_addr;
  logic [1:0] jmp_shift;
  wire recent_jump_pending = jmp_shift[1];
  always_ff @(posedge clk) begin
    if (rst_sync || ready_interrupt) begin
      ready_interrupt <= 0;
      jmp_shift <= 0;
    end else if (stall_n) begin
      ready_interrupt <= valid_interrupt_request;
      if (jump_en_ex) begin
        last_jump_addr <= jump_addr_ex;
        jmp_shift <= 2'b11;
      end else begin
        jmp_shift <= {jmp_shift[0], 1'b0};
      end
    end
  end

  wire is_interrupt = !exc_cause_id_ex.occurred && csr_mstatus.mie;
  assign any_interrupt_come = (csr_mie.meie && csr_mip.meip) || (csr_mie.mtie && csr_mip.mtip);
  assign valid_interrupt_request = any_interrupt_come && is_interrupt;
  assign exception_occurred = ready_interrupt || exc_cause_id_ex.occurred;
  assign new_mepc = recent_jump_pending ? last_jump_addr : instruction_addr_id_ex;

  logic [30:0] cause;
  assign new_mcause = {is_interrupt, cause};
  assign new_mtval  = 0;
  always_comb begin
    exception_jump_addr = {csr_mtvec[31:2], 2'b0};
    cause = exc_cause_id_ex.cause;
    if (is_interrupt) begin
      // 优先级: 外部->软件->定时器，这和中断号的顺序不一样
      if (csr_mie.meie && csr_mip.meip) begin
        cause = mextern_int_id;
        // cause = 31'd11;
        // 单核，无软件中断
        // end else if (csr_mie.msie && csr_mip.msip) begin
        //   valid_interrupt_request = 1;
        //   cause = 31'd3;
      end else if (csr_mie.mtie && csr_mip.mtip) begin
        cause = 31'd7;
      end
      if (csr_mtvec[1:0] == 2'b01) begin
        exception_jump_addr = {{csr_mtvec[31:2] + cause}, 2'b0};
      end
    end
  end


endmodule
