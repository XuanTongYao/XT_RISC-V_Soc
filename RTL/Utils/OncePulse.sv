// 模块: 单次脉冲发生器
// 功能: 触发延迟一个时钟周期后产生一个时钟周期的高脉冲，并解决了上电误触发bug，使用推荐的电路实现
// 版本: v1.5
// 作者: 姚萱彤
// <<< 参 数 >>> //
// TRIGGER:        选择控制信号触发方式，2'b11为双边沿触发，2'b01为上升沿，2'b10为下降沿
//
//
// <<< 端 口 >>> //
// clk:            时钟信号
// ctrl:           控制信号
// pulse:          生成的高脉冲信号

module OncePulse #(
    parameter bit [1:0] TRIGGER = 2'b11
) (
    input clk,
    input ctrl,
    output logic pulse
);

  // 赋初值消除上电误触发
  generate
    case (TRIGGER)
      2'b11: begin : gen_dual_edge
        logic [1:0] shift = 2'b00;
        assign pulse = shift[1] ^ shift[0];
        always_ff @(posedge clk) begin
          shift[0] <= ctrl;
          shift[1] <= shift[0];
        end
      end
      2'b01: begin : gen_posedge
        logic [1:0] shift = 2'b11;
        assign pulse = ~shift[1] & shift[0];
        always_ff @(posedge clk) begin
          shift[0] <= ctrl;
          shift[1] <= shift[0];
        end
      end
      2'b10: begin : gen_negsedge
        logic [1:0] shift = 2'b00;
        assign pulse = shift[1] & ~shift[0];
        always_ff @(posedge clk) begin
          shift[0] <= ctrl;
          shift[1] <= shift[0];
        end
      end
      default:
      begin : gen_none
        assign pulse = 1'b0;
      end
    endcase
  endgenerate



endmodule
