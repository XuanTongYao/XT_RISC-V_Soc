//----------纯组合逻辑----------//
module InstructionDecode
  import CoreConfig::*;
  import Exception_Pkg::*;
  import RV32I_Inst_Pkg::*;
#(
    parameter core_cfg_t CFG
) (
    // 来自IF_ID
    instruction_if.from_prev if_id_inst,

    // 与寄存器
    reg_r_if.core read_rs1,
    reg_r_if.core read_rs2,

    // 传递给ID_EX
    id_to_ex_if.to_next id_out,

    // 异常处理
    exception_if.source id_exception
);

  //----------指令信息提取----------//
  wire  [31:0] inst = if_id_inst.inst;
  wire  [ 6:0] opcode = inst[6:0];
  wire  [ 2:0] funct3 = inst[14:12];
  wire  [ 6:0] funct7 = inst[31:25];
  wire  [11:0] funct12 = inst[31:20];
  wire  [ 4:0] rs1 = inst[19:15];
  wire  [ 4:0] rs2 = inst[24:20];
  wire  [ 4:0] shamt = rs2;

  // 立即数
  wire  [31:0] imm_i = CFG.XLEN'($signed(inst[31:20]));
  wire  [31:0] imm_u = CFG.XLEN'($signed({inst[31:12], 12'b0}));
  wire  [31:0] imm_s = CFG.XLEN'($signed({inst[31:25], inst[11:7]}));
  wire  [31:0] imm_b = CFG.XLEN'($signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}));
  wire  [31:0] imm_j = CFG.XLEN'($signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}));
  wire  [31:0] imm_sys = CFG.XLEN'(inst[19:15]);


  // 源寄存器1的数据read_rs1.data一定和操作数1 operand1绑定
  // 源寄存器2的数据read_rs2.data一定和操作数2 operand2绑定
  // 立即数imm(imm_sys除外)一定与操作数2 operand2绑定
  logic [31:0] access_addr_imm;
  wire  [31:0] access_addr = read_rs1.data + access_addr_imm;
  always_comb begin
    // 寄存器读取地址直接赋值就行了
    // 刚好5bit不会越界，不同指令自己会选择是否读寄存器的
    read_rs1.addr = rs1;
    read_rs2.addr = rs2;
    id_out.operand1 = 'x;
    id_out.operand2 = 'x;
    id_out.reg_wen = 0;

    // 不可能同时读/写，地址计算可以共用加法器
    access_addr_imm = imm_i;
    id_out.load = 0;
    id_out.store = 0;
    id_out.load_addr = access_addr;
    id_out.store_addr = access_addr;
    id_out.store_data = read_rs2.data;

    id_exception.raise = 0;
    id_exception.code = ILLEGAL_INST;
    unique case (opcode)
      RV32I_OP_LUI: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = 0;
        id_out.operand2 = imm_u;
      end
      RV32I_OP_AUIPC: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = if_id_inst.addr;
        id_out.operand2 = imm_u;
      end
      RV32I_OP_JAL: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = if_id_inst.addr;
        id_out.operand2 = imm_j;
      end
      RV32I_OP_JALR: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = read_rs1.data;
        id_out.operand2 = imm_i;
      end
      RV32I_OP_B: begin
        unique case (funct3)
          RV32I_BEQ, RV32I_BNE, RV32I_BLT, RV32I_BGE, RV32I_BLTU, RV32I_BGEU: begin
            id_out.operand1 = read_rs1.data;
            id_out.operand2 = read_rs2.data;
          end
          default: ;
        endcase
      end
      RV32I_OP_L: begin
        unique case (funct3)
          RV32I_LB, RV32I_LH, RV32I_LW, RV32I_LBU, RV32I_LHU: begin
            id_out.reg_wen = 1;
            id_out.load = 1;
            access_addr_imm = imm_i;
          end
          default: ;
        endcase
      end
      RV32I_OP_S: begin
        unique case (funct3)
          RV32I_SB, RV32I_SH, RV32I_SW: begin
            id_out.store = 1;
            access_addr_imm = imm_s;
          end
          default: ;
        endcase
      end
      RV32I_OP_I: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = read_rs1.data;
        id_out.operand2 = imm_i;
      end
      RV32I_OP_R: begin
        id_out.reg_wen  = 1;
        id_out.operand1 = read_rs1.data;
        id_out.operand2 = read_rs2.data;
      end
      RV32I_OP_SYSTEM: begin
        unique case (funct3)
          RV32I_PRIVILEGED: begin
            unique case (funct12)
              RV32I_FUNCT12_ECALL, RV32I_FUNCT12_EBREAK: begin
                id_exception.raise = 1;
                id_exception.code  = funct12[0] ? BREAKPOINT : ECALL_FROM_M_MODE;
              end
              RV32I_FUNCT12_MRET: ;  // 不需要额外处理
              RV32I_FUNCT12_WFI:  ;  // WFI(在执行阶段处理)
              default: begin
                id_exception.raise = 1;
                id_exception.code  = ILLEGAL_INST;
              end
            endcase
          end
          ZICSR_CSRRW, ZICSR_CSRRS, ZICSR_CSRRC: begin
            id_out.reg_wen  = 1;
            id_out.operand1 = read_rs1.data;
          end
          ZICSR_CSRRWI, ZICSR_CSRRSI, ZICSR_CSRRCI: begin
            id_out.reg_wen  = 1;
            id_out.operand1 = imm_sys;
          end
          default: ;
        endcase
      end
      // 不执行，等效于NOP指令
      RV32I_OP_FENCE: ;
      default: begin
        id_exception.raise = 1;
        id_exception.code  = ILLEGAL_INST;
      end
    endcase
  end


endmodule
