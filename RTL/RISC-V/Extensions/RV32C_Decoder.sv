// 模块: RV32C指令解码器
// 功能: 将16位长度的RV32C指令解码为标准RV32I指令
// 版本: v0.1
// 作者: 姚萱彤
// <<< 端 口 >>> //
// rv32c_instruction:            RV32C指令
// rv32i_instruction:            RV32I指令
`include "../../Defines/InstructionDefines.sv"
`include "../../Defines/RV32C_InstructionDefines.sv"
module RV32C_Decoder (
    input [15:0] rv32c_instruction,
    output logic [31:0] rv32i_instruction
);

  //----------指令信息提取----------//
  wire [15:0] inst = rv32c_instruction;
  wire [1:0] opcode = inst[1:0];

  // 立即数
  wire [31:0] imm_ci_addi16sp = {{22{inst[12]}}, inst[12], inst[4:3], inst[5], inst[2], inst[6], 4'b0};
  wire [31:0] imm_ci_li = {{26{inst[12]}}, inst[12], inst[6:2]};
  wire [31:0] imm_ci_lui = {{14{inst[12]}}, inst[12], inst[6:2], 12'b0};
  wire [31:0] imm_ci = {24'b0, inst[3:2], inst[12], inst[6:4], 2'b0};
  wire [31:0] imm_css = {24'b0, inst[8:7], inst[12:9], 2'b0};
  wire [31:0] imm_ciw = {22'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b0};
  wire [31:0] imm_cl = {25'b0, inst[5], inst[12:10], inst[6], 2'b0};
  wire [31:0] imm_cs = imm_cl;
  wire [31:0] imm_cj = {
    {20{inst[12]}}, inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0
  };
  wire [31:0] imm_cb = {{23{inst[12]}}, inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0};

  wire [2:0] funct3 = inst[15:13];
  wire funct4_flag = inst[12];
  wire [1:0] funct2 = inst[11:10];
  wire [1:0] funct = inst[6:5];
  wire [4:0] rs1 = inst[11:7];
  wire [4:0] rs2 = inst[6:2];
  // rd没有固定位置
  wire [2:0] rs1_ = inst[9:7];
  wire [2:0] rs2_ = inst[4:2];
  wire [4:0] shamt = inst[6:2];  // 对于RV32Cshamt[5]一定为0



  //----------指令解压缩(opcode与funct3构成一个矩阵映射表，代码是依据这个表写的)----------//
  wire [4:0] decoded_rs1 = {2'b01, rs1_};
  wire [4:0] decoded_rs2 = {2'b01, rs2_};
  logic [7:0] rv32i_opcode;
  logic [4:0] rv32i_rd;
  logic [2:0] rv32i_funct3;
  logic [4:0] rv32i_rs1;
  logic [4:0] rv32i_rs2;
  logic rv32i_funct7_flag;
  // 不支持断点指令

  // 指令类型选择器
  logic [11:0] imm_type_i;
  wire [31:0] rv32i_instruction_type_i = {imm_type_i, rv32i_rs1, rv32i_funct3, rv32i_rd, rv32i_opcode};
  wire [31:0] rv32i_instruction_type_b = {
    {imm_cb[12], imm_cb[10:5]}, rv32i_rs2, rv32i_rs1, rv32i_funct3, {imm_cb[4:1], imm_cb[11]}, rv32i_opcode
  };
  logic [11:0] imm_type_s;
  wire [31:0] rv32i_instruction_type_s = {
    imm_type_s[11:5], rv32i_rs2, rv32i_rs1, rv32i_funct3, imm_type_s[4:0], rv32i_opcode
  };
  wire [31:0] rv32i_instruction_type_j = {
    {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12]}, rv32i_rd, rv32i_opcode
  };
  wire [31:0] rv32i_instruction_type_r = {
    {1'b0, rv32i_funct7_flag, 5'b0}, rv32i_rs2, rv32i_rs1, rv32i_funct3, rv32i_rd, rv32i_opcode
  };
  wire [31:0] rv32i_instruction_type_u = {imm_ci_lui[31:12], rv32i_rd, rv32i_opcode};
  always_comb begin
    rv32i_instruction = `INST_NOP;
    unique case (funct3)
      `INST_C_ADDI4SPN_ADDI_SLLI, `INST_C_LW_LWSP_LI: begin
        if (funct3 == 3'b000 && opcode == `INST_C_ADDI4SPN_ADDI_SLLI) begin
          // 移位与R 型指令更相似
          rv32i_instruction = rv32i_instruction_type_r;
        end else begin
          rv32i_instruction = rv32i_instruction_type_i;
        end
      end
      `INST_C_BNEZ: rv32i_instruction = rv32i_instruction_type_b;
      `INST_C_SW_SWSP_BEQZ: begin
        if (opcode == `INST_OP_C1) begin  // C.BEQZ，B 型指令
          rv32i_instruction = rv32i_instruction_type_b;
        end else begin  // C.SW/SWSP，S 型指令
          rv32i_instruction = rv32i_instruction_type_s;
        end
      end
      `INST_C_JAL, `INST_C_J: rv32i_instruction = rv32i_instruction_type_j;
      `INST_C_LUI_ADDI16SP: begin
        if (rs1 == 5'd2) begin
          rv32i_instruction = rv32i_instruction_type_i;
        end else begin
          rv32i_instruction = rv32i_instruction_type_u;
        end
      end
      `INST_C_REG_LOGIC_BIT_ALU_JALR: begin
        if ((opcode == `INST_OP_C2 && rs2 == 5'd0) || (opcode == `INST_OP_C1 && funct2 == 2'b10)) begin
          // C.JR/JALR，C.ANDI，I 型指令
          rv32i_instruction = rv32i_instruction_type_i;
        end else begin
          // C.AND/OR/XOR/SUB/MV/ADD，R 型指令
          // C.SRLI/SRAI，移位与R 型指令更相似
          rv32i_instruction = rv32i_instruction_type_r;
        end
      end
    endcase
  end

  // rs1与rs2选择器
  // TODO某些地方或许可以简化比较器
  always_comb begin
    rv32i_rs1 = 5'd0;
    rv32i_rs2 = 5'd0;
    unique case (opcode)
      `INST_OP_C0: begin
        if (funct3 == `INST_C_ADDI4SPN_ADDI_SLLI) begin
          rv32i_rs1 = `REG_SP;
        end else begin
          rv32i_rs1 = decoded_rs1;
        end

        rv32i_rs2 = decoded_rs2;
      end
      `INST_OP_C1: begin
        if (funct3 == `INST_C_ADDI4SPN_ADDI_SLLI || funct3 == `INST_C_LUI_ADDI16SP) begin
          rv32i_rs1 = rs1;
        end else if (funct3 == `INST_C_LW_LWSP_LI) begin
          rv32i_rs1 = 5'd0;
        end else begin
          rv32i_rs1 = decoded_rs1;
        end

        if (funct3 == `INST_C_REG_LOGIC_BIT_ALU_JALR && funct2 == 2'b11) rv32i_rs2 = decoded_rs2;
        else if (funct3 == `INST_C_REG_LOGIC_BIT_ALU_JALR) rv32i_rs2 = shamt;
        else rv32i_rs2 = 5'd0;
      end
      `INST_OP_C2: begin
        if (funct3 == `INST_C_LW_LWSP_LI || funct3 == `INST_C_SW_SWSP_BEQZ) begin
          rv32i_rs1 = `REG_SP;
        end else if (funct3 == `INST_C_MV && funct4_flag == 1'b0) begin
          rv32i_rs1 = 5'd0;
        end else begin
          rv32i_rs1 = rs1;
        end

        rv32i_rs2 = rs2;
      end
    endcase
  end

  // rd选择器
  always_comb begin
    rv32i_rd = 5'd0;
    unique case (opcode)
      `INST_OP_C0: rv32i_rd = decoded_rs2;
      `INST_OP_C1: begin
        if (funct3 == `INST_C_J || funct3 == `INST_C_JAL) begin
          rv32i_rd = (funct3 == `INST_C_J) ? 5'd0 : 5'd1;
        end else if (funct3 == `INST_C_REG_LOGIC_BIT_ALU_JALR) begin
          rv32i_rd = decoded_rs1;
        end else begin
          rv32i_rd = rs1;
        end
      end
      `INST_OP_C2: begin
        if (funct3 == `INST_C_JR_JALR) rv32i_rd = {4'b0, funct4_flag};
        else rv32i_rd = rs1;
      end
    endcase
  end

  // opcode选择器
  always_comb begin
    rv32i_opcode = `INST_OP_I;  // 默认值优化，出现次数很多
    unique case (funct3)
      `INST_C_J, `INST_C_JAL: rv32i_opcode = `INST_OP_JAL;
      `INST_C_BNEZ: rv32i_opcode = `INST_OP_B;
      `INST_C_LW_LWSP_LI: begin
        if (opcode != `INST_OP_C1) begin  // C.LW/LWSP
          rv32i_opcode = `INST_OP_L;
        end
      end
      `INST_C_LUI_ADDI16SP: begin
        if (rs1 != 5'd2) begin  // C.LUI
          rv32i_opcode = `INST_OP_LUI;
        end
      end
      `INST_C_SW_SWSP_BEQZ: begin
        if (opcode == `INST_OP_C1) begin  // C.BEQZ
          rv32i_opcode = `INST_OP_B;
        end else begin
          rv32i_opcode = `INST_OP_S;
        end
      end
      `INST_C_REG_LOGIC_BIT_ALU_JALR: begin
        if (opcode == `INST_OP_C2) begin
          rv32i_opcode = (rs2 == 5'd0) ? `INST_OP_JALR : `INST_OP_R_M;
        end else if (funct2 == 2'b11) begin
          rv32i_opcode = `INST_OP_R_M;
        end
      end
    endcase
  end

  // funct3和funct7选择器(JAL和U 型指令无funct3)
  always_comb begin
    rv32i_funct3 = `INST_ADDI;  // 默认值优化，出现次数很多
    rv32i_funct7_flag = 0;
    unique case (funct3)
      `INST_C_ADDI4SPN_ADDI_SLLI: begin
        if (opcode == `INST_OP_C2) begin  // C.SLLI
          rv32i_funct3 = `INST_SLLI;
        end
      end
      `INST_C_BNEZ: rv32i_funct3 = `INST_BNE;
      `INST_C_LW_LWSP_LI: begin
        if (opcode != `INST_OP_C1) begin  // C.LW/LWSP
          rv32i_funct3 = `INST_LW;
        end
      end
      `INST_C_SW_SWSP_BEQZ: begin
        if (opcode == `INST_OP_C1) begin  // C.BEQZ
          rv32i_funct3 = `INST_BEQ;
        end else begin
          rv32i_funct3 = `INST_SW;
        end
      end
      `INST_C_REG_LOGIC_BIT_ALU_JALR: begin
        if (opcode == `INST_OP_C2) begin
          rv32i_funct3 = (rs2 == 5'd0) ? 3'b000 : `INST_ADD_SUB;
        end else begin
          if (funct2 == 2'b11) begin
            if (funct == `INST_C_AND_FUNCT) begin
              rv32i_funct3 = `INST_AND;
            end else if (funct == `INST_C_OR_FUNCT) begin
              rv32i_funct3 = `INST_OR;
            end else if (funct == `INST_C_XOR_FUNCT) begin
              rv32i_funct3 = `INST_XOR;
            end else begin
              rv32i_funct3 = `INST_ADD_SUB;
            end
            rv32i_funct7_flag = (funct == `INST_C_SUB_FUNCT);
          end else if (funct2 == 2'b10) begin
            rv32i_funct3 = `INST_ANDI;
          end else begin
            rv32i_funct3 = `INST_SRLI_SRAI;
            rv32i_funct7_flag = (funct2 == 2'b01);
          end
        end
      end
    endcase
  end

  // 立即数选择器
  always_comb begin
    imm_type_s = imm_cs[11:0];
    imm_type_i = imm_ci_li[11:0];  // 默认值优化
    unique case (opcode)
      `INST_OP_C0: begin
        unique case (funct3)
          `INST_C_LW_LWSP_LI: imm_type_i = imm_cl[11:0];
          `INST_C_ADDI4SPN_ADDI_SLLI: imm_type_i = imm_ciw[11:0];
        endcase
      end
      `INST_OP_C1: begin
        unique case (funct3)
          `INST_C_LUI_ADDI16SP: imm_type_i = imm_ci_addi16sp[11:0];
        endcase
      end
      `INST_OP_C2: begin
        imm_type_s = imm_css[11:0];
        unique case (funct3)
          `INST_C_LW_LWSP_LI: imm_type_i = imm_ci[11:0];
          `INST_C_JR_JALR: imm_type_i = 12'b0;
        endcase
      end
    endcase
  end

endmodule
