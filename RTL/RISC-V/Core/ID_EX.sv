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
    id_to_ex_if.from_prev id_out,
    // 传递给EX
    id_to_ex_if.to_next   id_ex_out
);

  // 都是NOP指令了，指令地址 不需要清零，对处理异常也有好处(中断处理)
  always_ff @(posedge clk) begin
    if (stall_n) begin
      id_ex_inst.addr <= if_id_inst.addr;
      id_ex_out.load_addr <= id_out.load_addr;
      id_ex_out.store_addr <= id_out.store_addr;
      id_ex_out.store_data <= id_out.store_data;
      id_ex_out.operand1 <= id_out.operand1;
      id_ex_out.operand2 <= id_out.operand2;
    end
  end

  always_ff @(posedge clk, posedge rst) begin
    // 如果在执行模块有WFI命令时，不能在有异常指令时冲刷流水线
    if (rst || flush || (id_exception.raise && stall_n)) begin
      id_ex_out.load <= 0;
      id_ex_out.store <= 0;
      id_ex_inst.inst <= INST_NOP;
      id_ex_out.reg_wen <= 0;
    end else if (stall_n) begin
      id_ex_out.load <= id_out.load;
      id_ex_out.store <= id_out.store;
      id_ex_inst.inst <= if_id_inst.inst;
      id_ex_out.reg_wen <= id_out.reg_wen;
    end
  end


endmodule
