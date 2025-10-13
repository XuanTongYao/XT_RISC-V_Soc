// 模块: RV32C指令解码器
// 功能: 将16位长度的RV32C指令解码为标准RV32I指令
// 版本: v0.2
// 作者: 姚萱彤
// <<< 端 口 >>> //
// rv32c_instruction:            RV32C指令
// rv32i_instruction:            RV32I指令
// v0.1版本大约160个LUT4，还能凹
// v0.2版本大约155个LUT4，还能凹
module RVC_Decoder
  import RVC_Inst_Pkg::*;
  import RV32I_Inst_Pkg::*;
(
    input [15:0] rvc_inst,
    output logic [31:0] rv32i_inst,
    output logic illegal_rvc
);

  //----------指令信息提取----------//
  wire [15:0] inst = rvc_inst;

  wire [2:0] funct3 = inst[15:13];
  wire [3:0] funct4 = inst[15:12];
  wire [5:0] funct6 = inst[15:10];
  wire [1:0] funct2 = inst[6:5];
  wire [1:0] opcode = inst[1:0];

  wire [4:0] rs1 = inst[11:7];
  wire [4:0] rs2 = inst[6:2];
  wire [4:0] rd = inst[11:7];
  // rd没有固定位置，1.和rs1相同(指令同时含rs1和rd)，2.在rs2的位置上(指令不含rs2)
  wire [2:0] rs1_c = inst[9:7];
  wire [2:0] rs2_c = inst[4:2];
  wire [2:0] rd_c = inst[4:2];
  wire [4:0] shamt = inst[6:2];  // 对于RV32Cshamt[5]一定为0

  wire [4:0] decoded_rs1 = {2'b01, rs1_c};
  wire [4:0] decoded_rs2 = {2'b01, rs2_c};
  wire [4:0] decoded_rd = {2'b01, rd_c};

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


  // 不同象限选择结果
  logic [6:0] opcode_Q[3];
  logic [4:0] rs1_Q[3];
  logic [4:0] rs2_Q[3];
  logic [4:0] rd_Q[3];
  logic [2:0] funct3_Q[3];
  // R I S B U J
  // 0 1 2 3 4 5
  // logic [2:0] type_Q[3];

  //----------象限0----------//
  always_comb begin
    opcode_Q[0] = RV32I_OP_I;
    rs1_Q[0] = decoded_rs1;
    rs2_Q[0] = decoded_rs2;
    rd_Q[0] = decoded_rd;
    funct3_Q[0] = RV32I_ADDI;
    // type_Q[0] = 'd1;
    unique case (funct3)
      RVC_Q0_ADDI4SPN: begin
        opcode_Q[0] = RV32I_OP_I;
        rs1_Q[0] = X2_SP;
      end
      RVC_Q0_LW: begin
        opcode_Q[0] = RV32I_OP_L;
        funct3_Q[0] = RV32I_LW;
      end
      RVC_Q0_SW: begin
        opcode_Q[0] = RV32I_OP_S;
        funct3_Q[0] = RV32I_SW;
        // type_Q[0]   = 'd2;
      end
      default: ;
    endcase
  end


  //----------象限1----------//
  logic rv32i_funct7_flag;  // 只有R和移位指令用了funct7,全在象限1里
  logic addi16sp;
  always_comb begin
    opcode_Q[1] = RV32I_OP_I;
    rs1_Q[1] = decoded_rs1;
    rs2_Q[1] = decoded_rs2;
    rd_Q[1] = decoded_rs1;
    funct3_Q[1] = RV32I_ADDI;
    rv32i_funct7_flag = 0;
    addi16sp = 0;
    unique case (funct3)
      RVC_Q1_ADDI: begin
        opcode_Q[1] = RV32I_OP_I;
        rs1_Q[1] = rs1;
        rd_Q[1] = rs1;
      end
      RVC_Q1_JAL: begin
        opcode_Q[1] = RV32I_OP_JAL;
        rd_Q[1] = X1_RA;
      end
      RVC_Q1_LI: begin
        opcode_Q[1] = RV32I_OP_I;
        rs1_Q[1] = 0;
        rd_Q[1] = rd;
      end
      RVC_Q1_ADDI16SP_LUI: begin
        opcode_Q[1] = rs1 == X2_SP ? RV32I_OP_I : RV32I_OP_LUI;
        addi16sp = rs1 == X2_SP;
        rs1_Q[1] = rs1;
        rd_Q[1] = rs1;
      end
      RVC_Q1_MISC_ALU: begin
        if (funct6[1:0] == 2'b11) begin  // R
          opcode_Q[1] = RV32I_OP_R;
          if (funct2 == RVC_Q1_FUNCT2_SUB) begin
            funct3_Q[1] = RV32I_ADD_SUB;
            rv32i_funct7_flag = 1;
          end else if (funct2 == RVC_Q1_FUNCT2_XOR) begin
            funct3_Q[1] = RV32I_XOR;
          end else begin
            funct3_Q[1] = {1'b1, funct2};
          end
        end else begin
          opcode_Q[1] = RV32I_OP_I;
          // funct3_Q[1] = {1'b1,funct6[1],1'b1};
          if (funct6[1]) begin
            funct3_Q[1] = RV32I_ANDI;
          end else begin
            funct3_Q[1] = RV32I_SRLI_SRAI;
          end
          rv32i_funct7_flag = funct6[0];  // SRAI
        end
      end
      RVC_Q1_J: begin
        opcode_Q[1] = RV32I_OP_JAL;
        rd_Q[1] = 0;
      end
      RVC_Q1_BEQZ, RVC_Q1_BNEZ: begin
        opcode_Q[1] = RV32I_OP_B;
        rs2_Q[1] = 0;
        funct3_Q[1] = {2'b0, funct3[0]};
      end
      default: ;
    endcase
  end


  //----------象限2----------//
  always_comb begin
    opcode_Q[2] = RV32I_OP_I;
    rs1_Q[2] = rs1;
    rs2_Q[2] = rs2;
    rd_Q[2] = rd;
    funct3_Q[2] = RV32I_ADD_SUB;
    unique case (funct3)
      RVC_Q2_SLLI: begin
        // funct7 是0 正确
        opcode_Q[2] = RV32I_OP_I;
        funct3_Q[2] = RV32I_SLLI;
      end
      RVC_Q2_LWSP: begin
        opcode_Q[2] = RV32I_OP_L;
        rs1_Q[2] = X2_SP;
        funct3_Q[2] = RV32I_LW;
      end
      RVC_Q2_JALR_JR_MV_ADD: begin
        if (funct4[0] == 1'b0) begin  // JR_MV
          if (rs2 == 0) begin  // JR
            opcode_Q[2] = RV32I_OP_JALR;
            rd_Q[2] = 0;
            funct3_Q[2] = 0;
          end else begin  // MV
            opcode_Q[2] = RV32I_OP_R;
            rs1_Q[2] = 0;
            funct3_Q[2] = RV32I_ADD_SUB;
          end
        end else begin  // JALR_ADD
          if (rs1 == 0) begin  // EBREAK
            opcode_Q[2] = RV32I_OP_SYSTEM;
            funct3_Q[2] = 0;
          end else begin
            if (rs2 == 0) begin  // JALR
              opcode_Q[2] = RV32I_OP_JALR;
              rd_Q[2] = X1_RA;
              funct3_Q[2] = 0;
            end else begin
              opcode_Q[2] = RV32I_OP_R;
              funct3_Q[2] = RV32I_ADD_SUB;
            end
          end
        end
      end
      RVC_Q2_SWSP: begin
        opcode_Q[2] = RV32I_OP_S;
        rs1_Q[2] = X2_SP;
        funct3_Q[2] = RV32I_SW;
      end
      default: ;
    endcase
  end

  //----------象限输出----------//
  logic [6:0] rv32i_opcode;
  logic [4:0] rv32i_rs1;
  logic [4:0] rv32i_rs2;
  logic [4:0] rv32i_rd;
  logic [2:0] rv32i_funct3;
  always_comb begin
    illegal_rvc = 0;
    rv32i_opcode = opcode_Q[0];
    rv32i_rs1 = rs1_Q[0];
    rv32i_rs2 = rs2_Q[0];
    rv32i_rd = rd_Q[0];
    rv32i_funct3 = funct3_Q[0];
    if (opcode == 2'b11 || inst == 0) begin
      illegal_rvc = 1;
    end else begin
      rv32i_opcode = opcode_Q[opcode];
      rv32i_rs1 = rs1_Q[opcode];
      rv32i_rs2 = rs2_Q[opcode];
      rv32i_rd = rd_Q[opcode];
      rv32i_funct3 = funct3_Q[opcode];
    end
  end


  //----------解码输出----------//
  // 把代码分为不同的点位
  low_area_t low_area;
  upper_unpack_t upper_unpack;
  assign upper_unpack = {low_area, rv32i_rs1, rv32i_funct3};
  upper_area_t upper_area;
  logic [4:0] rd_area;
  always_comb begin
    rd_area = rv32i_rd;
    if (rv32i_opcode == RV32I_OP_B) begin
      rd_area = {imm_cb[4:1], imm_cb[11]};
    end else if (rv32i_opcode == RV32I_OP_S) begin
      if (opcode == RVC_OP_Q0) begin
        rd_area = imm_cs[4:0];
      end else begin
        rd_area = imm_css[4:0];
      end
    end else begin
      rd_area = rv32i_rd;
    end

    low_area.imm   = 0;
    upper_area.imm = 0;
    if (rv32i_opcode == RV32I_OP_LUI) begin
      upper_area.imm = imm_ci_lui[31:12];
    end else if (rv32i_opcode == RV32I_OP_JAL) begin
      upper_area.imm = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12]};
    end else begin
      if (rv32i_opcode == RV32I_OP_JALR) begin
        low_area.imm = 0;
      end else if (rv32i_opcode == RV32I_OP_L) begin
        if (opcode == RVC_OP_Q2) begin  // LWSP
          low_area.imm = imm_lwsp[11:0];
        end else begin  // LW
          low_area.imm = imm_cl[11:0];
        end
      end else if (rv32i_opcode == RV32I_OP_I) begin
        if (rv32i_funct3 == RV32I_SRLI_SRAI || rv32i_funct3 == RV32I_SLLI) begin  // 移位
          low_area.unpack.funct7 = {1'b0, rv32i_funct7_flag, 5'b0};
          low_area.unpack.rs2 = shamt;
        end else begin
          if (opcode == RVC_OP_Q0) begin
            low_area.imm = imm_ciw[11:0];
          end else if (opcode == RVC_OP_Q1 && addi16sp) begin
            low_area.imm = imm_addi16sp[11:0];
          end else begin
            low_area.imm = imm_ci[11:0];
          end
        end
      end else begin
        low_area.unpack.rs2 = rv32i_rs2;
        if (rv32i_opcode == RV32I_OP_B) begin
          low_area.unpack.funct7 = {imm_cb[12], imm_cb[10:5]};
        end else if (rv32i_opcode == RV32I_OP_S) begin
          if (opcode == RVC_OP_Q0) begin
            low_area.unpack.funct7 = imm_cs[11:5];
          end else begin
            low_area.unpack.funct7 = imm_css[11:5];
          end
        end else begin
          if (opcode == RVC_OP_Q1) begin
            low_area.unpack.funct7 = {1'b0, rv32i_funct7_flag, 5'b0};
          end else begin
            low_area.unpack.funct7 = 0;
          end
        end
      end
      upper_area.unpack = upper_unpack;
    end

  end

  assign rv32i_inst = {upper_area, rd_area, rv32i_opcode};


endmodule
