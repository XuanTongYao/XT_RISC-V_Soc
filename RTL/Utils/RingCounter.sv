// 模块: 环形计数器
// 功能: 使用循环移位寄存器作为计数器，代替加法计数器减少LUT使用(对小计数器效果很弱)
// 版本: v1.1
// 作者: 姚萱彤
// <<< 参 数 >>> //
// CYCLE:          计数周期数
//
// <<< 端 口 >>> //
// clk:            时钟信号
// clk_en:         计数启用信号
// rst:            重置信号
// q:              移位寄存器输出
// pulse:          循环完成脉冲信号

module RingCounter #(
    parameter int CYCLE = 2
) (
    input clk,
    input clk_en,
    input rst,
    output logic [CYCLE-1:0] q,
    output logic pulse
);
  localparam int ZERO_NUM = CYCLE - 1;
  localparam bit [CYCLE-1:0] INIT_VAL = {{ZERO_NUM{1'b0}}, 1'b1};

  generate
    if (CYCLE <= 1) begin : gen_none
      assign pulse = 1'b1;
    end else begin : gen_normal

      logic [CYCLE-1:0] shift_reg;
      assign pulse = shift_reg[CYCLE-1];
      assign q = shift_reg;
      always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
          shift_reg <= INIT_VAL;
        end else if (clk_en) begin
          shift_reg <= {shift_reg[CYCLE-2:0], shift_reg[CYCLE-1]};
        end
      end

    end

  endgenerate

endmodule
