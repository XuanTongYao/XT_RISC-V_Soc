`include "../../Defines/InstructionDefines.sv"

module ID_EX (
    input        clk,
    input        rst_sync,
    input        hold_flag,
    input        stall_n,
    // 来自ID
    input        ram_load_access_id,
    input [31:0] ram_load_addr_id,
    input [31:0] instruction_addr_id,
    input [31:0] instruction_id,
    input [31:0] operand1_id,
    input [31:0] operand2_id,
    input        reg_wen_id,
    input        exception_id,
    input        wait_for_interrupt,

    // 传递给EX
    output logic        ram_load_access_id_ex,
    output logic [31:0] ram_load_addr_id_ex,
    output logic [31:0] instruction_addr_id_ex,
    output logic [31:0] instruction_id_ex,
    output logic [31:0] operand1,
    output logic [31:0] operand2,
    output logic        reg_wen_id_ex
);

  // 都是NOP指令了，指令地址 不需要清零，对处理异常也有好处
  always_ff @(posedge clk) begin
    if (stall_n) begin
      instruction_addr_id_ex <= instruction_addr_id;
    end
    // 如果在执行模块有WFI命令时，不能在有异常指令时冲刷流水线
    if (rst_sync || hold_flag || (exception_id && stall_n)) begin
      ram_load_access_id_ex <= 0;
      instruction_id_ex <= `INST_NOP;
      operand1 <= 0;
      operand2 <= 0;
      reg_wen_id_ex <= 0;
    end else if (stall_n) begin
      ram_load_access_id_ex <= ram_load_access_id;
      ram_load_addr_id_ex <= ram_load_addr_id;
      instruction_id_ex <= instruction_id;
      operand1 <= operand1_id;
      operand2 <= operand2_id;
      reg_wen_id_ex <= reg_wen_id;
    end
  end


endmodule
