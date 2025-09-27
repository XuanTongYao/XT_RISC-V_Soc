`include "../../Defines/InstructionDefines.sv"

//----------纯组合逻辑----------//
module InstructionDecode
  import Exception_Pkg::*;
(
    // 来自IF_ID
    input [31:0] instruction_addr_if_id,
    input [31:0] instruction_if_id,

    // 与寄存器
    output logic [4:0] reg1_raddr,
    output logic [4:0] reg2_raddr,
    input [31:0] reg1_rdata,
    input [31:0] reg2_rdata,

    // 传递给ID_EX
    output logic        ram_load_access_id,
    output logic        ram_store_access_id,
    output logic [31:0] ram_load_addr_id,
    output logic [31:0] ram_store_addr_id,
    output logic [31:0] ram_store_data_id,
    output logic [31:0] instruction_addr_id,
    output logic [31:0] instruction_id,
    output logic [31:0] operand1_id,
    output logic [31:0] operand2_id,
    output logic        reg_wen_id,

    // 异常处理
    output exception_t exception_id
);

  assign instruction_addr_id = instruction_addr_if_id;
  assign instruction_id = instruction_if_id;

  //----------指令信息提取----------//
  wire [31:0] inst = instruction_if_id;
  wire [ 6:0] opcode = inst[6:0];  // R I S B U J

  // 立即数
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  wire [31:0] imm_sys = {27'b0, inst[19:15]};

  wire [ 2:0] funct3 = inst[14:12];  // R I S B
  wire [ 4:0] rs1 = inst[19:15];  // R I S B
  wire [ 4:0] rs2 = inst[24:20];
  wire [ 4:0] shamt = rs2;
  wire [ 6:0] funct7 = inst[31:25];
  wire [11:0] funct12 = inst[31:20];

  // 源寄存器1的数据reg1_rdata一定和操作数1 operand1_id绑定
  // 源寄存器2的数据reg2_rdata一定和操作数2 operand2_id绑定
  // 立即数imm(imm_sys除外)一定与操作数2 operand2_id绑定
  always_comb begin
    // 寄存器读取地址直接赋值就行了
    // 刚好5bit不会越界，不同指令自己会选择是否读寄存器的
    reg1_raddr = rs1;
    reg2_raddr = rs2;
    operand1_id = 0;
    operand2_id = 0;
    reg_wen_id = 0;

    // ram_load_addr有ram_load_access控制，大胆赋值即可
    ram_load_access_id = 0;
    ram_store_access_id = 0;
    // TODO这个完全可以放到ALU那边来计算吧，放到op1 op2里面来优化
    // 毕竟现在会在执行模块进行流水线停顿
    ram_load_addr_id = reg1_rdata + imm_i;
    ram_store_addr_id = reg1_rdata + imm_s;
    ram_store_data_id = reg2_rdata;

    exception_id.raise = 0;
    exception_id.code = ILLEGAL_INST;
    unique case (opcode)
      `INST_OP_LUI: begin
        reg_wen_id  = 1;
        operand1_id = 0;
        operand2_id = imm_u;
      end
      `INST_OP_AUIPC: begin
        reg_wen_id  = 1;
        operand1_id = instruction_addr_if_id;
        operand2_id = imm_u;
      end
      `INST_OP_JAL: begin
        reg_wen_id  = 1;
        operand1_id = instruction_addr_if_id;
        operand2_id = imm_j;
      end
      `INST_OP_JALR: begin
        reg_wen_id  = 1;
        operand1_id = reg1_rdata;
        operand2_id = imm_i;
      end
      `INST_OP_B: begin
        unique case (funct3)
          `INST_BEQ, `INST_BNE, `INST_BLT, `INST_BGE, `INST_BLTU, `INST_BGEU: begin
            operand1_id = reg1_rdata;
            operand2_id = reg2_rdata;
          end
          default: ;
        endcase
      end
      `INST_OP_L: begin
        unique case (funct3)
          `INST_LB, `INST_LH, `INST_LW, `INST_LBU, `INST_LHU: begin
            reg_wen_id = 1;
            ram_load_access_id = 1;
          end
          default: ;
        endcase
      end
      `INST_OP_S: begin
        unique case (funct3)
          `INST_SB, `INST_SH, `INST_SW: begin
            ram_store_access_id = 1;
          end
          default: ;
        endcase
      end
      `INST_OP_I: begin
        unique case (funct3)
          `INST_ADDI, `INST_SLTI, `INST_SLTIU, `INST_XORI, `INST_ORI, `INST_ANDI: begin
            reg_wen_id  = 1;
            operand1_id = reg1_rdata;
            operand2_id = imm_i;
          end
          `INST_SLLI, `INST_SRLI_SRAI: begin
            reg_wen_id  = 1;
            operand1_id = reg1_rdata;
            operand2_id = {27'b0, shamt};
          end
        endcase
      end
      `INST_OP_R_M: begin
        unique case (funct3)
          `INST_ADD_SUB, `INST_SLL, `INST_SLT, `INST_SLTU, `INST_XOR, `INST_SRL_SRA, `INST_OR, `INST_AND: begin
            reg_wen_id  = 1;
            operand1_id = reg1_rdata;
            operand2_id = reg2_rdata;
          end
        endcase
      end
      `INST_OP_SYSTEM: begin
        unique case (funct3)
          `INST_PRIVILEGED: begin
            unique case (funct12)
              `INST_FUNCT12_ECALL, `INST_FUNCT12_EBREAK: begin
                exception_id.raise = 1;
                exception_id.code  = funct12[0] ? BREAKPOINT : ECALL_FROM_M_MODE;
              end
              `INST_FUNCT12_MRET: ;  // 不需要额外处理
              `INST_FUNCT12_WFI:  ;  // WFI(在执行阶段处理)
              default: begin
                exception_id.raise = 1;
                exception_id.code  = ILLEGAL_INST;
              end
            endcase
          end
          `INST_CSRRW, `INST_CSRRS, `INST_CSRRC: begin
            reg_wen_id  = 1;
            operand1_id = reg1_rdata;
          end
          `INST_CSRRWI, `INST_CSRRSI, `INST_CSRRCI: begin
            reg_wen_id  = 1;
            operand1_id = imm_sys;
          end
          default: ;
        endcase
      end
      // 不执行，等效于NOP指令
      `INST_OP_FENCE: ;
      default: begin
        exception_id.raise = 1;
        exception_id.code  = ILLEGAL_INST;
      end
    endcase
  end


endmodule
