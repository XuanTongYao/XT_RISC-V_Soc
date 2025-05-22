module CoreReg (
    input clk,
    input rst_sync,
    input stall_n,

    // 读取
    input [4:0] reg1_raddr,
    input [4:0] reg2_raddr,
    output logic [31:0] reg1_rdata,
    output logic [31:0] reg2_rdata,

    // 写入
    input [4:0] reg_waddr,
    input [31:0] reg_wdata,
    input reg_wen

);
  // 0号寄存器X0固定为0，直接不写
  logic [31:0] core_reg[31];

  //----------数据控制----------//
  // 这样能极大降低资源使用？能正常运行吗？
  wire [4:0] reg1_raddr_sub1 = reg1_raddr - 1'b1;
  wire [4:0] reg2_raddr_sub1 = reg2_raddr - 1'b1;
  wire [4:0] reg_waddr_sub1 = reg_waddr - 1'b1;
  always_comb begin
    if (reg1_raddr == 0) begin
      reg1_rdata = 0;
    end else if (reg_wen && reg1_raddr == reg_waddr) begin
      reg1_rdata = reg_wdata;
    end else begin
      reg1_rdata = core_reg[reg1_raddr_sub1];
    end
  end

  always_comb begin
    if (reg2_raddr == 0) begin
      reg2_rdata = 0;
    end else if (reg_wen && reg2_raddr == reg_waddr) begin
      reg2_rdata = reg_wdata;
    end else begin
      reg2_rdata = core_reg[reg2_raddr_sub1];
    end
  end

  always_ff @(posedge clk) begin
    if (rst_sync) begin
      for (int i = 0; i < 31; ++i) begin
        core_reg[i] <= 0;
      end
    end else if (stall_n && reg_wen && reg_waddr != 0) begin
      core_reg[reg_waddr_sub1] <= reg_wdata;
    end
  end

endmodule
