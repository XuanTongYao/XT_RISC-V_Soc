// 模块: 环形计数器
// 功能: 使用循环移位寄存器作为计数器，代替加法计数器减少LUT使用(对小计数器效果很弱)
// 版本: v1.0
// 作者: 姚萱彤
// <<< 参 数 >>> //
// RST_EN:         是否启用Rst端口，如果不启用则仅依赖上电初值(状态可能会损坏)
// CYCLE:          计数周期数
//
// <<< 端 口 >>> //
// clk:            时钟信号
// rst:            重置信号
// pulse:          循环完成脉冲信号

module RingCounter #(
    parameter bit RST_EN = 0,
    parameter int CYCLE  = 2
) (
    input clk,
    input clk_en,
    input rst,
    output logic pulse
);
  localparam int ZERO_NUM = CYCLE - 1;

  // 赋初值消除上电误触发
  generate
    if (CYCLE <= 1) begin : gen_none
      assign pulse = 1'b1;
    end else begin : gen_valid
      if (RST_EN) begin : gen_rst
        logic [CYCLE-1:0] shift_reg;
        assign pulse = shift_reg[CYCLE-1];
        always_ff @(posedge clk) begin
          if (rst) begin
            shift_reg <= {{ZERO_NUM{1'b0}}, 1'b1};
          end else if (clk_en) begin
            shift_reg <= {shift_reg[CYCLE-2:0], shift_reg[CYCLE-1]};
          end
        end
      end else begin : gen_preload
        logic [CYCLE-1:0] shift_reg = {{ZERO_NUM{1'b0}}, 1'b1};
        assign pulse = shift_reg[CYCLE-1];
        always_ff @(posedge clk) begin
          if (clk_en) begin
            shift_reg <= {shift_reg[CYCLE-2:0], shift_reg[CYCLE-1]};
          end
        end
      end
    end

  endgenerate



endmodule
