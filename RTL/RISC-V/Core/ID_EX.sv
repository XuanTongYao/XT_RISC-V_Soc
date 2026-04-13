module ID_EX
  import Exception_Pkg::*;
  import RV32I_Inst_Pkg::*;
(
    input clk,
    input rst,
    input flush,
    input stall_n,

    instruction_if.from_prev if_id_inst,
    instruction_if.to_next   id_ex_inst,

    exception_if.observer id_exception,

    // 来自ID
    memory_access_if.from_prev id_memory,

    input [31:0] operand1_id,
    input [31:0] operand2_id,
    input        reg_wen_id,

    // 传递给EX
    memory_access_if.to_next id_ex_memory,

    output logic [31:0] operand1,
    output logic [31:0] operand2,
    output logic        reg_wen_id_ex
);

  // 都是NOP指令了，指令地址 不需要清零，对处理异常也有好处(中断处理)
  always_ff @(posedge clk) begin
    if (stall_n) begin
      id_ex_inst.addr <= if_id_inst.addr;
      id_ex_memory.load_addr <= id_memory.load_addr;
      id_ex_memory.store_addr <= id_memory.store_addr;
      id_ex_memory.store_data <= id_memory.store_data;
      operand1 <= operand1_id;
      operand2 <= operand2_id;
    end
  end

  always_ff @(posedge clk, posedge rst) begin
    // 如果在执行模块有WFI命令时，不能在有异常指令时冲刷流水线
    if (rst || flush || (id_exception.raise && stall_n)) begin
      id_ex_memory.load <= 0;
      id_ex_memory.store <= 0;
      id_ex_inst.inst <= INST_NOP;
      reg_wen_id_ex <= 0;
    end else if (stall_n) begin
      id_ex_memory.load <= id_memory.load;
      id_ex_memory.store <= id_memory.store;
      id_ex_inst.inst <= if_id_inst.inst;
      reg_wen_id_ex <= reg_wen_id;
    end
  end


endmodule
