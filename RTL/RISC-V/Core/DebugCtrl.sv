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
  wire step_debug = debug.dcsr.step && !flushing_pipeline;  // 等指令真正执行完成

  // 因为触发调试是异步的，采用与中断相同的策略
  // 等本条指令执行完成后再处理
  assign debug.bypass_wfi = dm_hart.haltreq;  // 跳过wfi
  assign debug.valid_haltreq = (dm_hart.haltreq || ebreak_debug || step_debug) && !debug.halt && stall_n;
  assign debug.resume = dm_hart.resumereq && !dm_hart.haltreq && debug.halted;

  logic will_havereset;
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      will_havereset <= 1;

      debug.halt <= 0;
      debug.halted <= 0;
      dm_hart.dm_state <= UNAVAIL;
    end else begin
      if (will_havereset) begin
        will_havereset <= 0;
        dm_hart.havereset <= 1;
        dm_hart.dm_state <= RUNNING;
      end else if (dm_hart.ackhavereset) begin
        dm_hart.havereset <= 0;
      end

      debug.halt <= debug.valid_haltreq;
      if (debug.halt) begin
        debug.halted <= 1;
        dm_hart.dm_state <= HALTED;
      end else if (debug.resume) begin
        debug.halted <= 0;
        dm_hart.dm_state <= RUNNING;
      end
    end
  end


  assign debug.new_dpc = resume_addr;
  always_ff @(posedge clk) begin
    if (debug.valid_haltreq) begin
      if (dm_hart.haltreq) begin
        debug.new_cause <= DEBUG_HALTREQ;
      end else if (ebreak_debug) begin
        debug.new_cause <= DEBUG_EBREAK;
      end else if (step_debug) begin
        debug.new_cause <= DEBUG_STEP;
      end
    end
  end


  //----------读写寄存器----------//
  logic completed;

  wire [15:0] regno = command0.regno;
  always_comb begin
    if (!command0.transfer) begin
      command0.completed = 1;
      command0.failed = 0;
    end else if (!debug.halted || command0.aarsize != 'd2 || regno >= FPR_NO_BASE) begin
      command0.completed = 1;
      command0.failed = 1;
    end else begin
      command0.completed = completed;
      command0.failed = 0;
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
