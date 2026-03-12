// 模块: RV32C指令解码器
// 功能: 将16位长度的RV32C指令解码为标准RV32I指令
// 版本: v0.4
// 作者: 姚萱彤
// <<< 端 口 >>> //
// rv32c_instruction:            RV32C指令
// rv32i_instruction:            RV32I指令
// v0.1版本大约160个LUT4，还能凹
// v0.2版本大约155个LUT4，还能凹
// v0.3版本大约140个LUT4，还能凹 (使用无关项优化)
// v0.4版本大约130个LUT4，还能凹 (使用扁平化优化)
module RVC_DecoderV04
  import RVC_Inst_Pkg::*;
  import RV32I_Inst_Pkg::*;
(
    input [15:0] rvc_inst,
    output logic [31:0] rv32i_inst,
    output logic illegal_rvc
);


  //----------指令信息提取----------//
  wire [15:0] inst = rvc_inst;

  wire [ 2:0] funct3 = inst[15:13];
  wire [ 3:0] funct4 = inst[15:12];
  wire [ 5:0] funct6 = inst[15:10];
  wire [ 1:0] funct2 = inst[6:5];
  wire [ 1:0] opcode = inst[1:0];

  wire [ 4:0] rs1 = inst[11:7];
  wire [ 4:0] rs2 = inst[6:2];
  wire [ 4:0] rd = inst[11:7];
  // rd没有固定位置，1.和rs1相同(指令同时含rs1和rd)，2.在rs2的位置上(指令不含rs2)
  wire [ 2:0] rs1_c = inst[9:7];
  wire [ 2:0] rs2_c = inst[4:2];
  wire [ 2:0] rd_c = inst[4:2];
  wire [ 4:0] shamt = inst[6:2];  // 对于RV32Cshamt[5]一定为0

  wire [ 4:0] decoded_rs1 = {2'b01, rs1_c};
  wire [ 4:0] decoded_rs2 = {2'b01, rs2_c};
  wire [ 4:0] decoded_rd = {2'b01, rd_c};

  // 立即数
  wire [31:0] imm_ci = ParseImmCI(inst);
  wire [31:0] imm_ci_lui = ParseImmCI_LUI(inst);
  wire [31:0] imm_addi16sp = ParseImmADDI16SP(inst);
  wire [31:0] imm_lwsp = ParseImmLWSP(inst);
  wire [31:0] imm_css = ParseImmCSS(inst);
  wire [31:0] imm_ciw = ParseImmCIW(inst);
  wire [31:0] imm_cl = ParseImmCL(inst);
  wire [31:0] imm_cs = ParseImmCS(inst);
  wire [31:0] imm_cb = ParseImmCB(inst);
  wire [31:0] imm_cj = ParseImmCJ(inst);


  //----------RVC解码器----------//
  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
  } imm12_t;
  typedef struct packed {
    imm12_t imm12;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    logic [4:0] opcode;
  } rv32i_inst_short_op_t;
  rv32i_inst_short_op_t inst_Q;

  assign rv32i_inst = {inst_Q, 2'b11};

  // JAL专属
  wire [19:0] imm_jal = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12]};

  always_comb begin
    illegal_rvc = 0;
    inst_Q = 'x;

    unique case (opcode)
      2'b00: begin
        unique case (funct3)
          RVC_Q0_ADDI4SPN: begin
            if (inst[12:2] == 0) illegal_rvc = 1;
            inst_Q.imm12 = imm_ciw[11:0];
            inst_Q.rs1 = X2_SP;
            inst_Q.funct3 = RV32I_ADDI;
            inst_Q.rd = decoded_rd;
            inst_Q.opcode = RV32I_OP_I[6:2];
          end
          RVC_Q0_LW: begin
            inst_Q.imm12 = imm_cl[11:0];
            inst_Q.rs1 = decoded_rs1;
            inst_Q.funct3 = RV32I_LW;
            inst_Q.rd = decoded_rd;
            inst_Q.opcode = RV32I_OP_L[6:2];
          end
          RVC_Q0_SW: begin
            inst_Q.imm12 = {imm_cs[11:5], decoded_rs2};
            inst_Q.rs1 = decoded_rs1;
            inst_Q.funct3 = RV32I_SW;
            inst_Q.rd = imm_cs[4:0];
            inst_Q.opcode = RV32I_OP_S[6:2];
          end
          default: illegal_rvc = 1;
        endcase
      end
      2'b01: begin
        // funct3码位都填满了
        unique case (funct3)
          RVC_Q1_ADDI, RVC_Q1_LI: begin
            inst_Q.imm12 = imm_ci[11:0];
            inst_Q.rs1 = funct3 == RVC_Q1_LI ? 0 : rs1;
            inst_Q.funct3 = RV32I_ADDI;
            inst_Q.rd = rd;
            inst_Q.opcode = RV32I_OP_I[6:2];
          end
          RVC_Q1_ADDI16SP_LUI: begin
            if (rd == X2_SP) begin  // ADDI16SP
              inst_Q.imm12 = imm_addi16sp[11:0];
              inst_Q.rs1 = rs1;
              inst_Q.funct3 = RV32I_ADDI;
              inst_Q.opcode = RV32I_OP_I[6:2];
            end else begin  // LUI
              inst_Q.imm12 = imm_ci_lui[31:20];
              inst_Q.rs1 = imm_ci_lui[19:15];
              inst_Q.funct3 = imm_ci_lui[14:12];
              inst_Q.opcode = RV32I_OP_LUI[6:2];
            end
            inst_Q.rd = rd;
          end
          RVC_Q1_MISC_ALU: begin
            inst_Q.rs1 = decoded_rs1;
            inst_Q.rd  = decoded_rs1;
            if (funct6[1:0] == 2'b11) begin  // R
              inst_Q.opcode = RV32I_OP_R[6:2];
              inst_Q.imm12.rs2 = decoded_rs2;
              inst_Q.imm12.funct7 = 7'b0;
              if (funct2 == RVC_Q1_FUNCT2_SUB) begin
                inst_Q.funct3 = RV32I_ADD_SUB;
                inst_Q.imm12.funct7 = 7'b0100000;
              end else if (funct2 == RVC_Q1_FUNCT2_XOR) begin
                inst_Q.funct3 = RV32I_XOR;
              end else begin
                inst_Q.funct3 = {1'b1, funct2};
              end
            end else begin
              inst_Q.opcode = RV32I_OP_I[6:2];
              // inst_Q.funct3 = {1'b1,funct6[1],1'b1};
              if (funct6[1]) begin
                inst_Q.imm12  = imm_ci[11:0];
                inst_Q.funct3 = RV32I_ANDI;
              end else begin
                inst_Q.imm12.funct7 = {1'b0, funct6[0], 5'b00000};
                inst_Q.imm12.rs2 = imm_ci[4:0];
                inst_Q.funct3 = RV32I_SRLI_SRAI;
              end
            end
          end
          RVC_Q1_JAL, RVC_Q1_J: begin
            inst_Q.imm12 = imm_jal[19:8];
            inst_Q.rs1 = imm_jal[7:3];
            inst_Q.funct3 = imm_jal[2:0];
            inst_Q.rd = funct3 == RVC_Q1_JAL ? X1_RA : 0;
            inst_Q.opcode = RV32I_OP_JAL[6:2];
          end
          RVC_Q1_BEQZ, RVC_Q1_BNEZ: begin
            inst_Q.imm12.funct7 = {imm_cb[12], imm_cb[10:5]};
            inst_Q.imm12.rs2 = 5'd0;
            inst_Q.rs1 = decoded_rs1;
            inst_Q.funct3 = {2'b0, funct3[0]};
            inst_Q.rd = {imm_cb[4:1], imm_cb[11]};
            inst_Q.opcode = RV32I_OP_B[6:2];
          end
        endcase
      end
      2'b10: begin
        unique case (funct3)
          RVC_Q2_SLLI: begin
            inst_Q.imm12 = {7'b0, imm_ci[4:0]};
            inst_Q.rs1 = rs1;
            inst_Q.funct3 = RV32I_SLLI;
            inst_Q.rd = rs1;
            inst_Q.opcode = RV32I_OP_I[6:2];
          end
          RVC_Q2_LWSP: begin
            inst_Q.imm12 = imm_lwsp[11:0];
            inst_Q.rs1 = X2_SP;
            inst_Q.funct3 = RV32I_LW;
            inst_Q.rd = rd;
            inst_Q.opcode = RV32I_OP_L[6:2];
          end
          RVC_Q2_JALR_JR_MV_ADD: begin
            inst_Q.funct3 = 0;  // EBREAK、JALR和ADD_SUB一样
            if (rs1 == 0) begin  // EBREAK
              inst_Q.imm12 = RV32I_FUNCT12_EBREAK;
              inst_Q.rs1 = rs1;
              inst_Q.rd = rd;
              inst_Q.opcode = RV32I_OP_SYSTEM[6:2];
            end else begin
              inst_Q.imm12 = {7'b0, rs2};
              if (rs2 == 0) begin  // JR_JALR
                inst_Q.rs1 = rs1;
                inst_Q.rd = funct4[0] ? X1_RA : 0;
                inst_Q.opcode = RV32I_OP_JALR[6:2];
              end else begin  // MV_ADD
                inst_Q.rs1 = funct4[0] ? rs1 : 0;
                inst_Q.rd = rd;
                inst_Q.opcode = RV32I_OP_R[6:2];
              end
            end
          end
          RVC_Q2_SWSP: begin
            inst_Q.imm12 = {imm_css[11:5], rs2};
            inst_Q.rs1 = X2_SP;
            inst_Q.funct3 = RV32I_SW;
            inst_Q.rd = imm_css[4:0];
            inst_Q.opcode = RV32I_OP_S[6:2];
          end
          default: illegal_rvc = 1;
        endcase
      end
      2'b11: illegal_rvc = 1;
    endcase
  end

endmodule
