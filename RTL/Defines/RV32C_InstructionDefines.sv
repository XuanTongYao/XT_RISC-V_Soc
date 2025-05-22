// 压缩指令过于混乱，用指令类型来分类没意义
//----------opcode----------//

`define INST_OP_C0 2'b00
`define INST_OP_C1 2'b01
`define INST_OP_C2 2'b10


//----------funct3定义----------//
`define INST_C_ADDI4SPN_ADDI_SLLI 3'b000
`define INST_C_JAL 3'b001
`define INST_C_J 3'b101
`define INST_C_LW_LWSP_LI 3'b010
`define INST_C_LUI_ADDI16SP 3'b011
`define INST_C_SW_SWSP_BEQZ 3'b110
`define INST_C_BNEZ 3'b111
`define INST_C_AND_OR_XOR_SUB_SRLI_SRAI_ANDI 3'b100
`define INST_C_REG_LOGIC_BIT_ALU_JALR `INST_C_AND_OR_XOR_SUB_SRLI_SRAI_ANDI


//----------CR 型指令----------//
// 寄存器链接跳转指令
`define INST_C_JR_JALR 3'b100


//----------CS 型指令----------//
// 寄存器指令funct
`define INST_C_AND_FUNCT 2'b11
`define INST_C_OR_FUNCT 2'b10
`define INST_C_XOR_FUNCT 2'b01
`define INST_C_SUB_FUNCT 2'b00


//----------常用指令定义----------//
`define INST_C_NOP 16'hF001

