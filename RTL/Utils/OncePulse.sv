// 模块: 单次脉冲发生器
// 功能: 触发延迟一个时钟周期后产生一个时钟周期宽度的稳定高脉冲，并解决了上电误触发bug
// 版本: v1.7
// 作者: 姚萱彤
// <<< 参 数 >>> //
// TRIGGER:        选择控制信号触发方式，2'b11为双边沿触发，2'b01为上升沿，2'b10为下降沿
// DELAY:          脉冲生成延迟，默认为1，也就是最经典的电路
//                 如果延迟设为0，则ctrl必须是寄存器的直接输出，不能经过额外组合逻辑，否则脉冲将不稳定
//
// <<< 端 口 >>> //
// clk:            时钟信号
// ctrl:           控制信号
// pulse:          生成的高脉冲信号

module OncePulse #(
    parameter int DELAY = 1,
    parameter bit [1:0] TRIGGER = 2'b11
) (
    input clk,
    input ctrl,
    output logic pulse
);
  localparam int REG_NUM = DELAY + 1;
  localparam bit REG_INIT_VAL = TRIGGER == 2'b01 ? 1'b1 : 1'b0;

  // 赋初值消除上电误触发
  logic [REG_NUM-1:0] shift = {REG_NUM{REG_INIT_VAL}};
  logic detect;  // 倒数第二个移位寄存器/控制信号
  logic detect_delay;  // 最后一个移位寄存器

  assign detect_delay = shift[REG_NUM-1];
  generate
    if (DELAY == 0) begin : gen_single_reg
      assign detect = ctrl;
      always_ff @(posedge clk) begin
        shift <= ctrl;
      end
    end else begin : gen_normal
      assign detect = shift[REG_NUM-2];
      always_ff @(posedge clk) begin
        shift[0] <= ctrl;
        shift[REG_NUM-1:1] <= shift[REG_NUM-2:0];
      end
    end
  endgenerate


  generate
    case (TRIGGER)
      2'b11: begin : gen_dual_edge
        assign pulse = detect ^ detect_delay;
      end
      2'b01: begin : gen_posedge
        assign pulse = detect & ~detect_delay;
      end
      2'b10: begin : gen_negsedge
        assign pulse = ~detect & detect_delay;
      end
      default:
      begin : gen_none
        assign pulse = 1'b0;
      end
    endcase
  endgenerate


endmodule
