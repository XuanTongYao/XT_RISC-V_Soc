// 数据停一个时钟周期可选
module IF_ID
  import Exception_Pkg::*;
  import RV32I_Inst_Pkg::*;
#(
    parameter bit INST_DELAY_1TICK = 1
) (
    input clk,
    input rst,
    input flush,
    input stall_n,

    // 中间传递
    instruction_if.from_prev if_inst,
    instruction_if.to_next   if_id_inst,

    input exception_if_raise
);

  // 指令地址一定会停一个周期
  // 都是NOP指令了，指令地址 不需要清零，对处理异常也有好处
  always_ff @(posedge clk) begin
    if (stall_n) if_id_inst.addr <= if_inst.addr;
  end

  generate
    if (INST_DELAY_1TICK) begin : gen_delay_1tick
      always_ff @(posedge clk, posedge rst) begin
        if (rst || flush || exception_if_raise) begin
          if_id_inst.inst <= INST_NOP;
        end else if (stall_n) begin
          if_id_inst.inst <= if_inst.inst;
        end
      end
    end else begin : gen_none_delay
      logic clear;
      always_ff @(posedge clk, posedge rst) begin
        if (rst) clear <= 1;
        else clear <= flush || exception_if_raise;
      end
      assign if_id_inst.inst = clear ? INST_NOP : if_inst.inst;
    end
  endgenerate



endmodule
