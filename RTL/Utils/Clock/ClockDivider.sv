// 模块: 时钟分频器
// 功能: 固定整数分频，支持奇/偶分频因子
// 版本: v0.3
// 作者: 姚萱彤
// <<< 参 数 >>> //
// DIV:            分频因子
//
//
// <<< 端 口 >>> //
// clk:            时钟信号
// clkout:         分频时钟信号输出

module ClockDivider #(
    parameter int unsigned DIV = 1
) (
    input      clk,
    output bit clkout
);

  generate
    if (DIV == 0) begin : gen_none
      assign clkout = 0;
    end else if (DIV == 1) begin : gen_direct
      assign clkout = clk;
    end else if ((DIV % 2) == 0) begin : gen_even_div
      if (DIV == 2) begin : gen_2_div
        always_ff @(posedge clk) begin
          clkout <= ~clkout;
        end
      end else begin : gen_2x_div
        localparam int unsigned CNT = (DIV / 2) - 1;
        localparam int unsigned WIDTH = $clog2(CNT + 1);

        logic [WIDTH-1:0] cnt_clk = 0;
        always_ff @(posedge clk) begin
          if (cnt_clk == CNT[WIDTH-1:0]) begin
            cnt_clk <= 0;
            clkout  <= ~clkout;
          end else begin
            cnt_clk <= cnt_clk + 1;
          end
        end
      end
    end else begin : gen_odd_div

      localparam int unsigned CNT = DIV - 1;
      localparam int unsigned CNT_HALF = (CNT / 2);
      localparam int unsigned WIDTH = $clog2(CNT + 1);

      logic [WIDTH-1:0] cnt_pos = 0;
      logic source_pos = 0;
      always_ff @(posedge clk) begin
        if (cnt_pos == CNT[WIDTH-1:0]) begin
          cnt_pos <= 0;
          source_pos <= ~source_pos;
        end else begin
          cnt_pos <= cnt_pos + 1;
          if (cnt_pos == CNT_HALF[WIDTH-1:0]) begin
            source_pos <= ~source_pos;
          end
        end
      end

      logic [WIDTH-1:0] cnt_neg = 0;
      logic source_neg = 0;
      always_ff @(negedge clk) begin
        if (cnt_neg == CNT[WIDTH-1:0]) begin
          cnt_neg <= 0;
          source_neg <= ~source_neg;
        end else begin
          cnt_neg <= cnt_neg + 1;
          if (cnt_neg == CNT_HALF[WIDTH-1:0]) begin
            source_neg <= ~source_neg;
          end
        end
      end

      assign clkout = source_pos | source_neg;

    end
  endgenerate

endmodule
