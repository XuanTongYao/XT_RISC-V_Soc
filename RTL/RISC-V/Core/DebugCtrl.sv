module DebugCtrl
  import CoreConfig::*;
  import Debug_Pkg::*;
  import Exception_Pkg::*;
#(
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,
    input stall_n,

    // 连接到外部
    dm_hart_minimal_if.hart dm_hart,
    dm_register_if.hart command0,

    input exception_t exception_commit,
    input [CFG.PC_LEN-1:0] resume_addr,
    input flushing_pipeline,

    debug_if.controller debug,

    output logic debug_override_csr,
    output logic debug_override_gpr,
    csr_rw_if.core debug_rw_csr,
    reg_r_if.core debug_read_gpr,
    reg_w_if.core debug_write_gpr
);
  wire ebreak_debug = exception_commit.raise && exception_commit.code == BREAKPOINT && debug.dcsr.ebreakm;
  wire step_debug = debug.dcsr.step && !flushing_pipeline;  // 等指令真正到执行模块

  // 由haltreq和step触发调试采用与中断相同的策略: 等本条指令执行完成后再处理
  // 而其他的ebreak与reset_halt等触发调试立即发生，相当于异常
  assign debug.bypass_wfi = dm_hart.haltreq;  // 跳过wfi
  assign debug.valid_delay_halt = (dm_hart.haltreq || step_debug) && !debug.halt && stall_n;
  assign debug.resume = dm_hart.resumereq && !dm_hart.haltreq && debug.halted;
  assign debug.halted = debug.debug_mode;  // 因为没有实现程序缓冲区 调试模式一定停止内核

  logic recover_from_reset;
  logic delay_halt;
  wire  reset_halt = (recover_from_reset && dm_hart.haltreq);
  assign debug.halt = (delay_halt || ebreak_debug || reset_halt) && !debug.debug_mode;
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      recover_from_reset <= 1;

      delay_halt <= 0;
      debug.debug_mode <= 0;
      dm_hart.dm_state <= UNAVAIL;
    end else begin
      if (delay_halt) begin
        delay_halt <= 0;
      end else begin
        delay_halt <= debug.valid_delay_halt;
      end

      if (recover_from_reset) begin
        recover_from_reset <= 0;
        dm_hart.havereset  <= 1;
        dm_hart.dm_state   <= RUNNING;
      end else if (dm_hart.ackhavereset) begin
        dm_hart.havereset <= 0;
      end

      if (debug.halt) begin
        debug.debug_mode <= 1;
        dm_hart.dm_state <= HALTED;
      end else if (debug.resume) begin
        debug.debug_mode <= 0;
        dm_hart.dm_state <= RUNNING;
      end
    end
  end


  assign debug.new_dpc = reset_halt ? '0 : resume_addr;
  always_comb begin
    debug.new_cause = 'x;
    if (reset_halt) begin
      debug.new_cause = DEBUG_HALTREQ;
    end else if (ebreak_debug) begin
      debug.new_cause = DEBUG_EBREAK;
    end else if (delay_halt) begin
      if (dm_hart.haltreq) begin
        debug.new_cause = DEBUG_HALTREQ;
      end else if (step_debug) begin
        debug.new_cause = DEBUG_STEP;
      end
    end
  end



  //----------读写寄存器----------//
  logic completed;

  wire [15:0] regno = command0.regno;
  wire invalid_command0_arg = command0.aarsize != 'd2 || regno >= FPR_NO_BASE;
  always_comb begin
    if (!command0.transfer) begin
      command0.completed = 1;
      command0.failed = 0;
      command0.error_state = 0;
    end else if (!debug.halted || invalid_command0_arg) begin
      command0.completed = 1;
      command0.failed = 1;
      command0.error_state = !invalid_command0_arg;  // 因处理器状态而失败
    end else begin
      command0.completed = completed;
      command0.failed = 0;
      command0.error_state = 0;
    end
  end

  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      debug_override_csr <= 0;
      debug_override_gpr <= 0;
      completed <= 0;
    end else begin
      if (debug_override_csr) begin
        debug_override_csr <= 0;
        completed <= 1;
        command0.rdata <= debug_rw_csr.rdata;
      end
      if (debug_override_gpr) begin
        debug_override_gpr <= 0;
        completed <= 1;
        command0.rdata <= debug_read_gpr.data;
      end
      if (completed) completed <= 0;

      if (command0.transfer && !command0.failed) begin
        if (regno >= GPR_NO_BASE) begin
          debug_override_gpr   <= 1;
          debug_write_gpr.en   <= command0.write;
          debug_write_gpr.addr <= regno[4:0];
          debug_write_gpr.data <= command0.wdata;
          debug_read_gpr.addr  <= regno[4:0];
        end else begin
          debug_override_csr <= 1;
          debug_rw_csr.ren   <= !command0.write;
          debug_rw_csr.wen   <= command0.write;
          debug_rw_csr.addr  <= regno[11:0];
          debug_rw_csr.wdata <= command0.wdata;
        end
      end
    end
  end

endmodule
