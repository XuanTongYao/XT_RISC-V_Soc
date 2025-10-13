//----------纯组合逻辑----------//
module InstructionExecute
  import CoreConfig::*;
  import RV32I_Inst_Pkg::*;
(
    // 来自ID_EX
    input        ram_load_access_id_ex,
    input        ram_store_access_id_ex,
    input [31:0] ram_load_addr_id_ex,
    input [31:0] ram_store_addr_id_ex,
    input [31:0] ram_store_data_id_ex,
    input [31:0] instruction_addr_id_ex,
    input [31:0] next_pc,                 // 下一个PC其实就存在IF_ID里面，不需要单独寄存
    input [31:0] instruction_id_ex,
    input [31:0] operand1,
    input [31:0] operand2,
    input        reg_wen_id_ex,

    // 传递给寄存器
    output logic [ 4:0] reg_waddr,
    output logic [31:0] reg_wdata,
    output logic        reg_wen,

    // 访问控制与状态寄存器
    output logic trap_returned,
    output logic csr_ren,
    output logic csr_wen,
    output logic [11:0] csr_rwaddr,
    output logic [31:0] csr_wdata,
    input [31:0] csr_rdata,
    input [PC_LEN-1:0] csr_mepc,

    // 访存
    output logic ram_load_en,
    output logic ram_store_en,
    output logic [31:0] ram_load_addr,
    output logic [31:0] ram_store_addr,
    input [31:0] ram_load_data,
    output logic [31:0] ram_store_data,
    output logic [1:0] ram_store_width,

    // 传递给核心控制器
    output logic [31:0] jump_addr_ex,
    output logic jump_en_ex,
    output logic wait_for_interrupt
);
  // TODO实际上这个地方应该有异常判断
  wire [31:0] inst = instruction_id_ex;


  //----------指令信息提取----------//
  wire [6:0] opcode = inst[6:0];  // R I S B U J
  wire [4:0] rd = inst[11:7];  // R I U J

  // 立即数
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // 其他
  wire [2:0] funct3 = inst[14:12];  // R I S B
  wire [4:0] rs1 = inst[19:15];  // R I S B
  wire [4:0] rs2 = inst[24:20];
  wire [4:0] shamt = rs2;
  wire [6:0] funct7 = inst[31:25];
  wire [11:0] funct12 = inst[31:20];


  //----------运算逻辑单元----------//
  // 运算单元
  // 加法器允许进位输入且不消耗额外资源，我们可以利用这来实现一个加/减法器，更节省资源
  // 减法实际上是op1 + ~op2 + 1'b1
  // 大多数器件的原语都支持加减法器同时实现(消耗少量资源)
  logic add_sub;
  wire [31:0] alu_add = add_sub ? operand1 + operand2 : operand1 - operand2;
  wire [31:0] alu_xor = operand1 ^ operand2;
  wire [31:0] alu_or = operand1 | operand2;
  wire [31:0] alu_and = operand1 & operand2;
  wire [31:0] alu_shift_left = operand1 << operand2[4:0];
  wire [31:0] alu_shift_right_l = operand1 >> operand2[4:0];
  wire [31:0] alu_shift_right_a = $signed(operand1) >>> operand2[4:0];
  wire [31:0] alu_base_addr_offset = instruction_addr_id_ex + imm_b;
  // 逻辑单元
  wire alu_equal = operand1 == operand2;
  wire alu_less_signed = $signed(operand1) < $signed(operand2);
  wire alu_less_unsigned = operand1 < operand2;
  logic alu_less;
  always_comb begin
    unique case (funct3)
      RV32I_SLT, RV32I_SLTI: begin
        alu_less = alu_less_signed;
      end
      default: alu_less = alu_less_unsigned;
    endcase
  end

  // Load指令访存数据的高位扩展
  logic extension_bit;
  always_comb begin
    unique case (funct3)
      RV32I_LB: extension_bit = ram_load_data[7];
      RV32I_LH: extension_bit = ram_load_data[15];
      default:  extension_bit = 0;
    endcase
  end
  wire [31:0] extension_byte = {{24{extension_bit}}, ram_load_data[7:0]};
  wire [31:0] extension_halfword = {{16{extension_bit}}, ram_load_data[15:0]};

  // 源寄存器1的数据reg_src1_data一定和操作数1 operand1_id绑定
  // 源寄存器2的数据reg_src2_data一定和操作数2 operand2_id绑定
  // 立即数imm一定与操作数2 operand2_id绑定
  always_comb begin
    ram_load_en = ram_load_access_id_ex;
    ram_store_en = ram_store_access_id_ex;
    ram_load_addr = ram_load_addr_id_ex;
    ram_store_addr = ram_store_addr_id_ex;
    ram_store_data = ram_store_data_id_ex;
    ram_store_width = funct3[1:0];
    add_sub = 1;

    reg_wen = reg_wen_id_ex;
    reg_waddr = rd;
    reg_wdata = 0;
    jump_addr_ex = 0;
    jump_en_ex = 0;

    trap_returned = 0;
    csr_ren = 0;
    csr_wen = 0;
    csr_rwaddr = inst[31:20];
    csr_wdata = 0;

    wait_for_interrupt = 0;
    unique case (opcode)
      RV32I_OP_LUI:   reg_wdata = alu_add;
      RV32I_OP_AUIPC: reg_wdata = alu_add;
      RV32I_OP_JAL, RV32I_OP_JALR: begin
        reg_wdata = next_pc;
        jump_addr_ex = {alu_add[31:1], 1'b0};
        jump_en_ex = 1;
      end
      RV32I_OP_B: begin
        jump_addr_ex = alu_base_addr_offset;
        // 有jump_en_ex防止误操作，jump_addr_ex大胆赋值即可
        unique case (funct3)
          RV32I_BEQ:  jump_en_ex = alu_equal;
          RV32I_BNE:  jump_en_ex = !alu_equal;
          RV32I_BLT:  jump_en_ex = alu_less_signed;
          RV32I_BGE:  jump_en_ex = !alu_less_signed;
          RV32I_BLTU: jump_en_ex = alu_less_unsigned;
          RV32I_BGEU: jump_en_ex = !alu_less_unsigned;
          default:    ;
        endcase
      end
      RV32I_OP_L: begin
        unique case (funct3)
          RV32I_LB, RV32I_LBU: reg_wdata = extension_byte;
          RV32I_LH, RV32I_LHU: reg_wdata = extension_halfword;
          RV32I_LW:            reg_wdata = ram_load_data;
          default:             ;
        endcase
      end
      RV32I_OP_S:     ;  // 已经在译码阶段完成处理
      RV32I_OP_I: begin
        unique case (funct3)
          RV32I_ADDI:              reg_wdata = alu_add;
          RV32I_SLTI, RV32I_SLTIU: reg_wdata = {31'b0, alu_less};
          RV32I_XORI:              reg_wdata = alu_xor;
          RV32I_ORI:               reg_wdata = alu_or;
          RV32I_ANDI:              reg_wdata = alu_and;
          RV32I_SLLI:              reg_wdata = alu_shift_left;
          RV32I_SRLI_SRAI: begin
            if (funct7[5] == 1'b1) begin
              //SRAI
              reg_wdata = alu_shift_right_a;
            end else begin
              //SRLI
              reg_wdata = alu_shift_right_l;
            end
          end
        endcase
      end
      RV32I_OP_R: begin
        unique case (funct3)
          RV32I_ADD_SUB: begin
            if (funct7[5] == 1'b1) begin
              add_sub = 0;
            end
            reg_wdata = alu_add;
          end
          RV32I_SLT, RV32I_SLTU: reg_wdata = {31'b0, alu_less};
          RV32I_XOR:             reg_wdata = alu_xor;
          RV32I_OR:              reg_wdata = alu_or;
          RV32I_AND:             reg_wdata = alu_and;
          RV32I_SLL:             reg_wdata = alu_shift_left;
          RV32I_SRL_SRA: begin
            if (funct7[5] == 1'b1) begin
              //SRA
              reg_wdata = alu_shift_right_a;
            end else begin
              //SRL
              reg_wdata = alu_shift_right_l;
            end
          end
        endcase
      end
      RV32I_OP_SYSTEM: begin
        // CSR指令都是原子指令
        reg_wdata = csr_rdata;
        unique case (funct3)
          RV32I_PRIVILEGED: begin
            unique case (funct12)
              RV32I_FUNCT12_ECALL, RV32I_FUNCT12_EBREAK: ;  //等效于NOP指令
              RV32I_FUNCT12_MRET: begin
                jump_en_ex = 1;
                jump_addr_ex = PadPC(csr_mepc);
                trap_returned = 1;
              end
              RV32I_FUNCT12_WFI: wait_for_interrupt = 1;  // WFI(告知内核控制器请求等待)
              default: ;
            endcase
          end
          ZICSR_CSRRW, ZICSR_CSRRWI: begin
            csr_ren   = rd != 5'd0;
            csr_wen   = 1;
            csr_wdata = operand1;
          end
          ZICSR_CSRRS, ZICSR_CSRRSI: begin
            csr_ren   = 1;
            csr_wen   = rs1 != 5'd0;
            csr_wdata = operand1 | csr_rdata;
          end
          ZICSR_CSRRC, ZICSR_CSRRCI: begin
            csr_ren   = 1;
            csr_wen   = rs1 != 5'd0;
            csr_wdata = ~operand1 & csr_rdata;
          end
          default: ;
        endcase
      end
      // 不执行，等效于NOP指令
      RV32I_OP_FENCE: ;
      default:        ;
    endcase

  end

endmodule
