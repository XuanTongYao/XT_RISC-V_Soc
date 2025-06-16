//----------opcode和funct3定义----------//

//----------R 型指令----------//
// 寄存器操作指令
`define INST_OP_R_M 7'b0110011
`define INST_ADD_SUB 3'b000
`define INST_SLL 3'b001
`define INST_SLT 3'b010
`define INST_SLTU 3'b011
`define INST_XOR 3'b100
`define INST_SRL_SRA 3'b101
`define INST_OR 3'b110
`define INST_AND 3'b111



// 乘法指令 暂时用不到
// `define INST_MUL 3'b000
// `define INST_MULH 3'b001
// `define INST_MULHSU 3'b010
// `define INST_MULHU 3'b011
// `define INST_DIV 3'b100
// `define INST_DIVU 3'b101
// `define INST_REM 3'b110
// `define INST_REMU 3'b111




//----------I 型指令----------//
// 短立即数指令
`define INST_OP_I 7'b0010011
`define INST_ADDI 3'b000
`define INST_SLTI 3'b010
`define INST_SLTIU 3'b011
`define INST_XORI 3'b100
`define INST_ORI 3'b110
`define INST_ANDI 3'b111
`define INST_SLLI 3'b001
`define INST_SRLI_SRAI 3'b101

// LOAD指令
`define INST_OP_L 7'b0000011
`define INST_LB 3'b000
`define INST_LH 3'b001
`define INST_LW 3'b010
`define INST_LBU 3'b100
`define INST_LHU 3'b101

// 寄存器链接跳转指令
`define INST_OP_JALR 7'b1100111

// FENCE指令
`define INST_OP_FENCE 7'b0001111



//----------S 型指令----------//
// STORE指令
`define INST_OP_S 7'b0100011
`define INST_SB 3'b000
`define INST_SH 3'b001
`define INST_SW 3'b010


//----------B 型指令----------//
// 条件跳转指令
`define INST_OP_B 7'b1100011
`define INST_BEQ 3'b000
`define INST_BNE 3'b001
`define INST_BLT 3'b100
`define INST_BGE 3'b101
`define INST_BLTU 3'b110
`define INST_BGEU 3'b111


//----------U 型指令----------//
`define INST_OP_LUI 7'b0110111
`define INST_OP_AUIPC 7'b0010111


//----------J 型指令----------//
// 链接跳转指令
`define INST_OP_JAL 7'b1101111


//----------系统指令----------//
// 特权指令
`define INST_OP_SYSTEM 7'b1110011
`define INST_PRIVILEGED 3'b000
// 环境调用
`define INST_FUNCT12_ECALL 12'b0000000_00000
`define INST_FUNCT12_EBREAK 12'b0000000_00001
// 其他特权指令
`define INST_FUNCT12_SRET 12'b0001000_00010
`define INST_FUNCT12_MRET 12'b0011000_00010
`define INST_FUNCT12_WFI 12'b0001000_00101
`define INST_FUNCT12_VMA 12'b0001001_00000
// CSR扩展
`define INST_CSRRW 3'b001
`define INST_CSRRS 3'b010
`define INST_CSRRC 3'b011
`define INST_CSRRWI 3'b101
`define INST_CSRRSI 3'b110
`define INST_CSRRCI 3'b111


//----------常用指令定义----------//
`define INST_NOP 32'h00000013
`define INST_NOP_OP 7'b0000001
`define INST_MRET 32'h30200073
`define INST_RET 32'h00008067





//----------寄存器ABI名称定义----------//
`define REG_SP 5'd2;

