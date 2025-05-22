// 模块: 时钟分频器
// 功能: 固定整数分频
// 版本: v0.2
// 作者: 姚萱彤
// <<< 参 数 >>> //
// DIV:            分频因子
//
//
// <<< 端 口 >>> //
// clk:            时钟信号
// clkout:         分频时钟信号输出

module ClockDivider #(
    parameter int DIV = 1
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
          if (cnt_clk == CNT) begin
            cnt_clk <= 0;
            clkout  <= ~clkout;
          end else begin
            cnt_clk <= cnt_clk + 1'b1;
          end
        end
      end
    end else begin : gen_odd_div
      // FIXME综合出的结构貌似有点奇怪

      localparam int unsigned CNT_1 = DIV - 1;
      localparam int unsigned CNT_2 = (CNT_1 / 2);
      localparam int unsigned WIDTH_1 = $clog2(CNT_1 + 1);

      //----------计数器----------//
      logic [WIDTH_1-1:0] cnt_pos = 0;
      always_ff @(posedge clk) begin
        if (cnt_pos == CNT_1) begin
          cnt_pos <= 0;
        end else cnt_pos <= cnt_pos + 1'b1;
      end

      logic [WIDTH_1-1:0] cnt_neg = 0;
      always_ff @(negedge clk) begin
        if (cnt_neg == CNT_1) begin
          cnt_neg <= 0;
        end else cnt_neg <= cnt_neg + 1'b1;
      end

      //----------信号生成----------//
      logic souce_pos = 0;
      logic souce_pos_valid;
      always_ff @(posedge clk) begin
        if (cnt_pos == 0 || cnt_pos == CNT_2) begin
          souce_pos <= ~souce_pos;
        end
      end

      logic souce_neg = 0;
      logic souce_neg_valid;
      always_ff @(negedge clk) begin
        if (cnt_neg == 0 || cnt_neg == CNT_2) begin
          souce_neg <= ~souce_neg;
        end
      end

      always_comb begin
        if (cnt_pos == 0 || cnt_pos == CNT_2) begin
          souce_pos_valid = ~souce_pos;
        end else begin
          souce_pos_valid = souce_pos;
        end
        if (cnt_neg == 0 || cnt_neg == CNT_2) begin
          souce_neg_valid = ~souce_neg;
        end else begin
          souce_neg_valid = souce_neg;
        end
      end

      always_ff @(posedge clk) begin
        clkout <= souce_pos_valid | souce_neg_valid;
      end
    end
  endgenerate

endmodule
