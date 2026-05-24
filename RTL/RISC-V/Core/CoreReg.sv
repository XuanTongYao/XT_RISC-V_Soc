module CoreReg
  import CoreConfig::*;
#(
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,
    input stall_n,
    input debug_override_gpr,

    // 读取
    reg_r_if.regs read_rs1,
    reg_r_if.regs read_rs2,
    reg_r_if.regs debug_read_gpr,
    // 写入
    reg_w_if.regs write_rd,
    reg_w_if.regs debug_write_gpr,

    // 调试控制器
    debug_if.core debug
);
  // 调试器覆盖
  logic wen;
  logic [4:0] waddr;
  logic [CFG.XLEN-1:0] wdata;
  always_comb begin
    if (debug_override_gpr) begin
      wen   = debug_write_gpr.en;
      waddr = debug_write_gpr.addr;
      wdata = debug_write_gpr.data;
    end else begin
      wen   = write_rd.en;
      waddr = write_rd.addr;
      wdata = write_rd.data;
    end
  end

  // 0号寄存器X0固定为0
  logic [CFG.XLEN-1:0] core_reg[CFG.REG_COUNT];

  //----------数据控制----------//
  always_comb begin
    if (read_rs1.addr == 0) begin
      read_rs1.data = 0;
    end else if (wen && read_rs1.addr == waddr) begin
      read_rs1.data = wdata;
    end else begin
      read_rs1.data = core_reg[read_rs1.addr];
    end
  end

  always_comb begin
    if (read_rs2.addr == 0) begin
      read_rs2.data = 0;
    end else if (wen && read_rs2.addr == waddr) begin
      read_rs2.data = wdata;
    end else begin
      read_rs2.data = core_reg[read_rs2.addr];
    end
  end

  always_comb begin
    if (debug_read_gpr.addr == 0) begin
      debug_read_gpr.data = 0;
    end else begin
      debug_read_gpr.data = core_reg[debug_read_gpr.addr];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst && (stall_n || debug.halted) && wen && waddr != 0) begin
      core_reg[waddr] <= wdata;
    end
  end

endmodule
