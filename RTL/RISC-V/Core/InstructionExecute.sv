//----------纯组合逻辑----------//
module InstructionExecute
  import CoreConfig::*;
  import RV32I_Inst_Pkg::*;
#(
    parameter core_cfg_t CFG
) (
    // 来自ID_EX
    instruction_if.from_prev id_ex_inst,
    memory_access_if.from_prev id_ex_memory,
    input [31:0] next_pc,  // 下一个PC其实就存在IF_ID里面，不需要单独寄存
    input [31:0] operand1,
    input [31:0] operand2,
    input reg_wen_id_ex,

    // 写入目的寄存器
    reg_w_if.core write_rd,

    // 访问控制与状态寄存器
    csr_rw_if.core csr_rw,
    output logic trap_returned,
    input [CFG.PC_LEN-1:0] csr_mepc,

    // 访存
    output logic ram_load_en,
    output logic ram_store_en,
    output logic [31:0] ram_load_addr,
    output logic [31:0] ram_store_addr,
    input [31:0] ram_load_data,
    output logic [31:0] ram_store_data,
    output logic [1:0] ram_access_width,

    // 传递给核心控制器
    output logic [31:0] jump_addr_ex,
    output logic jump_en_ex,
    output logic wfi
);
  // TODO实际上这个地方应该有异常判断


  //----------指令信息提取----------//
  wire [31:0] inst = id_ex_inst.inst;
  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  wire [11:0] funct12 = inst[31:20];
  wire [4:0] rs1 = inst[19:15];
  wire [4:0] rs2 = inst[24:20];
  wire [4:0] rd = inst[11:7];

  // 立即数
  wire [31:0] imm_i = CFG.XLEN'($signed(inst[31:20]));
  wire [31:0] imm_u = CFG.XLEN'($signed({inst[31:12], 12'b0}));
  wire [31:0] imm_s = CFG.XLEN'($signed({inst[31:25], inst[11:7]}));
  wire [31:0] imm_b = CFG.XLEN'($signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}));
  wire [31:0] imm_j = CFG.XLEN'($signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}));



  //----------算术逻辑单元----------//
  // 大多数器件都支持加/减法器同时实现(消耗少量额外资源)
  logic add_sub;
  wire [31:0] alu_add = add_sub ? operand1 + operand2 : operand1 - operand2;
  wire [31:0] alu_xor = operand1 ^ operand2;
  wire [31:0] alu_or = operand1 | operand2;
  wire [31:0] alu_and = operand1 & operand2;
  wire [31:0] alu_shift_left = operand1 << operand2[4:0];
  wire [31:0] alu_shift_right_l = operand1 >> operand2[4:0];
  wire [31:0] alu_shift_right_a = $signed(operand1) >>> operand2[4:0];
  wire [31:0] alu_base_addr_offset = id_ex_inst.addr + imm_b;

  wire alu_equal = operand1 == operand2;
  wire alu_less_signed = $signed(operand1) < $signed(operand2);
  wire alu_less_unsigned = operand1 < operand2;
  logic alu_less;
  always_comb begin
    // 实际上SLT和SLTI的funct3相同
    if (funct3 == RV32I_SLT || funct3 == RV32I_SLTI) alu_less = alu_less_signed;
    else alu_less = alu_less_unsigned;
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
    ram_load_en = id_ex_memory.load;
    ram_store_en = id_ex_memory.store;
    ram_load_addr = id_ex_memory.load_addr;
    ram_store_addr = id_ex_memory.store_addr;
    ram_store_data = id_ex_memory.store_data;
    ram_access_width = funct3[1:0];
    add_sub = 1;

    write_rd.en = reg_wen_id_ex;
    write_rd.addr = rd;
    write_rd.data = 'x;
    jump_addr_ex = 'x;
    jump_en_ex = 0;

    trap_returned = 0;
    csr_rw.ren = 0;
    csr_rw.wen = 0;
    csr_rw.addr = inst[31:20];
    csr_rw.wdata = 'x;

    wfi = 0;
    unique case (opcode)
      RV32I_OP_LUI:   write_rd.data = alu_add;
      RV32I_OP_AUIPC: write_rd.data = alu_add;
      RV32I_OP_JAL, RV32I_OP_JALR: begin
        write_rd.data = next_pc;
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
          RV32I_LB, RV32I_LBU: write_rd.data = extension_byte;
          RV32I_LH, RV32I_LHU: write_rd.data = extension_halfword;
          RV32I_LW:            write_rd.data = ram_load_data;
          default:             ;
        endcase
      end
      RV32I_OP_S:     ;  // 已经在译码阶段完成处理
      RV32I_OP_I: begin
        unique case (funct3)
          RV32I_ADDI:              write_rd.data = alu_add;
          RV32I_SLTI, RV32I_SLTIU: write_rd.data = CFG.XLEN'(alu_less);
          RV32I_XORI:              write_rd.data = alu_xor;
          RV32I_ORI:               write_rd.data = alu_or;
          RV32I_ANDI:              write_rd.data = alu_and;
          RV32I_SLLI:              write_rd.data = alu_shift_left;
          RV32I_SRLI_SRAI: begin
            if (funct7[5] == 1'b1) begin
              //SRAI
              write_rd.data = alu_shift_right_a;
            end else begin
              //SRLI
              write_rd.data = alu_shift_right_l;
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
            write_rd.data = alu_add;
          end
          RV32I_SLT, RV32I_SLTU: write_rd.data = CFG.XLEN'(alu_less);
          RV32I_XOR:             write_rd.data = alu_xor;
          RV32I_OR:              write_rd.data = alu_or;
          RV32I_AND:             write_rd.data = alu_and;
          RV32I_SLL:             write_rd.data = alu_shift_left;
          RV32I_SRL_SRA: begin
            if (funct7[5] == 1'b1) begin
              //SRA
              write_rd.data = alu_shift_right_a;
            end else begin
              //SRL
              write_rd.data = alu_shift_right_l;
            end
          end
        endcase
      end
      RV32I_OP_SYSTEM: begin
        // CSR指令都是原子指令
        write_rd.data = csr_rw.rdata;
        unique case (funct3)
          RV32I_PRIVILEGED: begin
            unique case (funct12)
              RV32I_FUNCT12_ECALL, RV32I_FUNCT12_EBREAK: ;  //等效于NOP指令
              RV32I_FUNCT12_MRET: begin
                jump_en_ex = 1;
                jump_addr_ex = CFG.XLEN'(PadPC(csr_mepc, CFG.PC_ZEROS));
                trap_returned = 1;
              end
              RV32I_FUNCT12_WFI: wfi = 1;  // WFI(告知内核控制器请求等待)
              default: ;
            endcase
          end
          ZICSR_CSRRW, ZICSR_CSRRWI: begin
            csr_rw.ren   = rd != 5'd0;
            csr_rw.wen   = 1;
            csr_rw.wdata = operand1;
          end
          ZICSR_CSRRS, ZICSR_CSRRSI: begin
            csr_rw.ren   = 1;
            csr_rw.wen   = rs1 != 5'd0;
            csr_rw.wdata = operand1 | csr_rw.rdata;
          end
          ZICSR_CSRRC, ZICSR_CSRRCI: begin
            csr_rw.ren   = 1;
            csr_rw.wen   = rs1 != 5'd0;
            csr_rw.wdata = ~operand1 & csr_rw.rdata;
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
