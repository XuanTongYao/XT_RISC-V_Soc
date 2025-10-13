package RV32I_Inst_Pkg;

  //----------R 型指令----------//
  // 寄存器操作指令
  localparam bit [6:0] RV32I_OP_R = 7'b0110011;
  localparam bit [2:0] RV32I_ADD_SUB = 3'b000;
  localparam bit [2:0] RV32I_SLL = 3'b001;
  localparam bit [2:0] RV32I_SLT = 3'b010;
  localparam bit [2:0] RV32I_SLTU = 3'b011;
  localparam bit [2:0] RV32I_XOR = 3'b100;
  localparam bit [2:0] RV32I_SRL_SRA = 3'b101;
  localparam bit [2:0] RV32I_OR = 3'b110;
  localparam bit [2:0] RV32I_AND = 3'b111;


  //----------I 型指令----------//
  // 短立即数指令
  localparam bit [6:0] RV32I_OP_I = 7'b0010011;
  localparam bit [2:0] RV32I_ADDI = 3'b000;
  localparam bit [2:0] RV32I_SLTI = 3'b010;
  localparam bit [2:0] RV32I_SLTIU = 3'b011;
  localparam bit [2:0] RV32I_XORI = 3'b100;
  localparam bit [2:0] RV32I_ORI = 3'b110;
  localparam bit [2:0] RV32I_ANDI = 3'b111;
  localparam bit [2:0] RV32I_SLLI = 3'b001;
  localparam bit [2:0] RV32I_SRLI_SRAI = 3'b101;

  // LOAD指令
  localparam bit [6:0] RV32I_OP_L = 7'b0000011;
  localparam bit [2:0] RV32I_LB = 3'b000;
  localparam bit [2:0] RV32I_LH = 3'b001;
  localparam bit [2:0] RV32I_LW = 3'b010;
  localparam bit [2:0] RV32I_LBU = 3'b100;
  localparam bit [2:0] RV32I_LHU = 3'b101;

  // 寄存器链接跳转指令
  localparam bit [6:0] RV32I_OP_JALR = 7'b1100111;

  // FENCE指令
  localparam bit [6:0] RV32I_OP_FENCE = 7'b0001111;


  //----------S 型指令----------//
  // STORE指令
  localparam bit [6:0] RV32I_OP_S = 7'b0100011;
  localparam bit [2:0] RV32I_SB = 3'b000;
  localparam bit [2:0] RV32I_SH = 3'b001;
  localparam bit [2:0] RV32I_SW = 3'b010;


  //----------B 型指令----------//
  // 条件跳转指令
  localparam bit [6:0] RV32I_OP_B = 7'b1100011;
  localparam bit [2:0] RV32I_BEQ = 3'b000;
  localparam bit [2:0] RV32I_BNE = 3'b001;
  localparam bit [2:0] RV32I_BLT = 3'b100;
  localparam bit [2:0] RV32I_BGE = 3'b101;
  localparam bit [2:0] RV32I_BLTU = 3'b110;
  localparam bit [2:0] RV32I_BGEU = 3'b111;


  //----------U 型指令----------//
  localparam bit [6:0] RV32I_OP_LUI = 7'b0110111;
  localparam bit [6:0] RV32I_OP_AUIPC = 7'b0010111;


  //----------J 型指令----------//
  // 链接跳转指令
  localparam bit [6:0] RV32I_OP_JAL = 7'b1101111;


  //----------系统指令----------//
  localparam bit [6:0] RV32I_OP_SYSTEM = 7'b1110011;
  // 特权指令
  localparam bit [2:0] RV32I_PRIVILEGED = 3'b000;
  // 环境调用
  localparam bit [11:0] RV32I_FUNCT12_ECALL = 12'b0000000_00000;
  localparam bit [11:0] RV32I_FUNCT12_EBREAK = 12'b0000000_00001;
  // 其他特权指令
  localparam bit [11:0] RV32I_FUNCT12_SRET = 12'b0001000_00010;
  localparam bit [11:0] RV32I_FUNCT12_MRET = 12'b0011000_00010;
  localparam bit [11:0] RV32I_FUNCT12_WFI = 12'b0001000_00101;
  localparam bit [11:0] RV32I_FUNCT12_VMA = 12'b0001001_00000;
  // Zicsr扩展CSR寄存器(懒得单独写一个文件了)
  localparam bit [2:0] ZICSR_CSRRW = 3'b001;
  localparam bit [2:0] ZICSR_CSRRS = 3'b010;
  localparam bit [2:0] ZICSR_CSRRC = 3'b011;
  localparam bit [2:0] ZICSR_CSRRWI = 3'b101;
  localparam bit [2:0] ZICSR_CSRRSI = 3'b110;
  localparam bit [2:0] ZICSR_CSRRCI = 3'b111;


  //----------常用指令定义----------//
  localparam bit [31:0] INST_NOP = 32'h00000013;
  localparam bit [31:0] INST_MRET = 32'h30200073;
  localparam bit [31:0] INST_RET = 32'h00008067;


  //----------指令结构----------//
  // 可以把指令划分为几个区域
  // up rd op
  // up又可以分为 low rs1 funct3
  // low又可以分为 funct7 rs2
  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
  } low_unpack_t;

  typedef union packed {
    logic [11:0] imm;
    low_unpack_t unpack;
  } low_area_t;

  typedef struct packed {
    low_area_t  low_area;
    logic [4:0] rs1;
    logic [2:0] funct3;
  } upper_unpack_t;

  typedef union packed {
    logic [19:0]   imm;
    upper_unpack_t unpack;
  } upper_area_t;

  typedef struct packed {
    upper_area_t upper_area;
    logic [4:0]  rd_area;
    logic [6:0]  opcode;
  } rv32i_inst_t;


  //----------寄存器别名----------//
  localparam bit [4:0] X1_RA = 5'd1;
  localparam bit [4:0] X2_SP = 5'd2;
  localparam bit [4:0] X3_GP = 5'd3;
  localparam bit [4:0] X4_TP = 5'd4;

endpackage
