// 压缩指令过于混乱，用指令类型来分类没意义
package RVC_Inst_Pkg;
  localparam bit [1:0] RVC_OP_Q0 = 2'b00;
  localparam bit [1:0] RVC_OP_Q1 = 2'b01;
  localparam bit [1:0] RVC_OP_Q2 = 2'b10;

  localparam bit [2:0] RVC_Q0_ADDI4SPN = 3'b000;
  localparam bit [2:0] RVC_Q0_LW = 3'b010;
  localparam bit [2:0] RVC_Q0_SW = 3'b110;

  localparam bit [2:0] RVC_Q1_ADDI = 3'b000;
  localparam bit [2:0] RVC_Q1_JAL = 3'b001;
  localparam bit [2:0] RVC_Q1_LI = 3'b010;
  localparam bit [2:0] RVC_Q1_ADDI16SP_LUI = 3'b011;
  localparam bit [2:0] RVC_Q1_MISC_ALU = 3'b100;
  localparam bit [2:0] RVC_Q1_J = 3'b101;
  localparam bit [2:0] RVC_Q1_BEQZ = 3'b110;
  localparam bit [2:0] RVC_Q1_BNEZ = 3'b111;
  // funct2
  localparam bit [1:0] RVC_Q1_FUNCT2_SUB = 2'b00;
  localparam bit [1:0] RVC_Q1_FUNCT2_XOR = 2'b01;
  localparam bit [1:0] RVC_Q1_FUNCT2_OR = 2'b10;
  localparam bit [1:0] RVC_Q1_FUNCT2_AND = 2'b11;

  localparam bit [2:0] RVC_Q2_SLLI = 3'b000;
  localparam bit [2:0] RVC_Q2_LWSP = 3'b010;
  localparam bit [2:0] RVC_Q2_JALR_JR_MV_ADD = 3'b100;
  localparam bit [2:0] RVC_Q2_SWSP = 3'b110;


  // 结构体不包含opcode
  typedef struct packed {
    logic [3:0] funct4;
    logic [4:0] rd_rs1;
    logic [4:0] rs2;
  } cr_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic imm_1;
    logic [4:0] rd_rs1;
    logic [4:0] imm_0;
  } ci_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic [5:0] imm;
    logic [4:0] rs2;
  } css_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic [7:0] imm;
    logic [2:0] rd_c;
  } ciw_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic [2:0] imm_1;
    logic [2:0] rs1_c;
    logic [1:0] imm_0;
    logic [2:0] rd_c;
  } cl_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic [2:0] imm_1;
    logic [2:0] rs1_c;
    logic [1:0] imm_0;
    logic [2:0] rs2_c;
  } cs_t;
  typedef struct packed {
    logic [5:0] funct6;
    logic [2:0] rd_rs1_c;
    logic [1:0] funct2;
    logic [2:0] rs2_c;
  } ca_t;
  typedef struct packed {
    logic [2:0] funct3;
    logic [2:0] offset_1;
    logic [2:0] rd_rs1_c;
    logic [4:0] offset_0;
  } cb_t;
  typedef struct packed {
    logic [2:0]  funct3;
    logic [10:0] jump_addr;
  } cj_t;

  typedef union packed {
    cr_t  CR;
    ci_t  CI;
    css_t CSS;
    ciw_t CIW;
    cl_t  CL;
    ca_t  CA;
    cb_t  CB;
    cj_t  CJ;
  } rvc_inst_t;


  // 立即数
  function automatic bit [31:0] ParseImmCI(logic [15:0] inst);
    return {{26{inst[12]}}, inst[12], inst[6:2]};
  endfunction
  function automatic bit [31:0] ParseImmCI_LUI(logic [15:0] inst);
    return {{14{inst[12]}}, inst[12], inst[6:2], 12'b0};
  endfunction
  function automatic bit [31:0] ParseImmADDI16SP(logic [15:0] inst);
    return {{22{inst[12]}}, inst[12], inst[4:3], inst[5], inst[2], inst[6], 4'b0};
  endfunction
  function automatic bit [31:0] ParseImmLWSP(logic [15:0] inst);
    return {24'b0, inst[3:2], inst[12], inst[6:4], 2'b0};
  endfunction
  function automatic bit [31:0] ParseImmCSS(logic [15:0] inst);
    return {24'b0, inst[8:7], inst[12:9], 2'b0};
  endfunction
  function automatic bit [31:0] ParseImmCIW(logic [15:0] inst);
    return {22'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b0};
  endfunction
  function automatic bit [31:0] ParseImmCL(logic [15:0] inst);
    return {25'b0, inst[5], inst[12:10], inst[6], 2'b0};
  endfunction
  function automatic bit [31:0] ParseImmCS(logic [15:0] inst);
    return ParseImmCL(inst);
  endfunction
  function automatic bit [31:0] ParseImmCB(logic [15:0] inst);
    return {{23{inst[12]}}, inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0};
  endfunction
  function automatic bit [31:0] ParseImmCJ(logic [15:0] inst);
    return {{20{inst[12]}}, inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0};
  endfunction

endpackage

