//----------M扩展指令----------//
package M_Inst_Pkg;

  localparam bit [6:0] RV32M_OP_M = 7'b0110011;
  localparam bit [2:0] RV32M_MUL = 3'b000;
  localparam bit [2:0] RV32M_MULH = 3'b001;
  localparam bit [2:0] RV32M_MULHSU = 3'b010;
  localparam bit [2:0] RV32M_MULHU = 3'b011;
  localparam bit [2:0] RV32M_DIV = 3'b100;
  localparam bit [2:0] RV32M_DIVU = 3'b101;
  localparam bit [2:0] RV32M_REM = 3'b110;
  localparam bit [2:0] RV32M_REMU = 3'b111;



  localparam bit [6:0] RV64M_OP_M = 7'b0111011;
  localparam bit [2:0] RV64M_MULW = 3'b000;
  localparam bit [2:0] RV64M_DIVW = 3'b100;
  localparam bit [2:0] RV64M_DIVUW = 3'b101;
  localparam bit [2:0] RV64M_REMW = 3'b110;
  localparam bit [2:0] RV64M_REMUW = 3'b111;



endpackage
