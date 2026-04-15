module CoreReg
  import CoreConfig::*;
#(
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,
    input stall_n,

    // 读取
    reg_r_if.regs read_rs1,
    reg_r_if.regs read_rs2,
    // 写入
    reg_w_if.regs write_rd
);
  // 0号寄存器X0固定为0
  logic [CFG.XLEN-1:0] core_reg[CFG.REG_NUMS];

  //----------数据控制----------//
  always_comb begin
    if (read_rs1.addr == 0) begin
      read_rs1.data = 0;
    end else if (write_rd.en && read_rs1.addr == write_rd.addr) begin
      read_rs1.data = write_rd.data;
    end else begin
      read_rs1.data = core_reg[read_rs1.addr];
    end
  end

  always_comb begin
    if (read_rs2.addr == 0) begin
      read_rs2.data = 0;
    end else if (write_rd.en && read_rs2.addr == write_rd.addr) begin
      read_rs2.data = write_rd.data;
    end else begin
      read_rs2.data = core_reg[read_rs2.addr];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst && stall_n && write_rd.en && write_rd.addr != 0) begin
      core_reg[write_rd.addr] <= write_rd.data;
    end
  end

endmodule
