// 模块: 简易时钟监控器
// 功能: 监控PLL锁定情况，自动复位或响应外部复位信号
//       在电源稳定前拉高PLL复位
//       若在最大锁定周期到达时，未能成功锁定，尝试重新复位锁定
// 版本: v0.2
// 作者: 姚萱彤
// <<< 参 数 >>> //
// MAX_LOCK_PERIOD:     最大锁定周期(相对于独立时钟)
// POWERUP_PERIOD:      电源稳定周期(相对于独立时钟)，为0则禁用
//
//
// <<< 端 口 >>> //
// independent_clk:     独立时钟信号
// extern_pll_rst:      外部复位信号
// pll_lock:            PLL锁定情况
// pll_rst:             PLL复位输出
module ClockMonitor #(
    parameter int MAX_LOCK_PERIOD = 360_000,
    parameter int POWERUP_PERIOD  = 12_000_000
) (
    input independent_clk,
    input extern_pll_rst,
    input pll_lock,
    output logic pll_rst
);
  localparam int MAX_PERIOD = POWERUP_PERIOD >= MAX_LOCK_PERIOD ? POWERUP_PERIOD : MAX_LOCK_PERIOD;
  localparam int WIDTH = $clog2(MAX_PERIOD);
  localparam int CNT = MAX_LOCK_PERIOD - 1;
  localparam int CNT_1 = POWERUP_PERIOD - 1;

  logic extern_pll_rst_reg;
  always_ff @(posedge independent_clk) begin
    extern_pll_rst_reg <= extern_pll_rst;
  end

  // pll_rst要持续1ns，肯定满足要求
  logic reseting = 0;
  logic [WIDTH-1:0] counter;
  generate
    if (POWERUP_PERIOD == 0) begin : gen_without_powerup_check
      always_ff @(posedge independent_clk) begin
        if (reseting) begin
          if (counter == CNT) begin
            reseting <= 0;
            if (!pll_lock) pll_rst <= 1;  // 尝试重新复位
          end
        end else if (pll_rst) begin
          if (!extern_pll_rst_reg) begin
            pll_rst  <= 0;
            reseting <= 1;
          end
        end else if (extern_pll_rst_reg || !pll_lock) begin
          pll_rst <= 1;
        end
      end

      always_ff @(posedge independent_clk) begin
        if (counter == CNT) begin
          counter <= 0;
        end else if (reseting) begin
          counter <= counter + 1'b1;
        end
      end
    end else begin : gen_with_powerup_check
      logic powerup = 0;
      always_ff @(posedge independent_clk) begin
        if (!powerup) begin
          pll_rst <= 1;
          if (counter == CNT_1) powerup <= 1;
        end else if (reseting) begin
          if (counter == CNT) begin
            reseting <= 0;
            if (!pll_lock) pll_rst <= 1;  // 尝试重新复位
          end
        end else if (pll_rst) begin
          if (!extern_pll_rst_reg) begin
            pll_rst  <= 0;
            reseting <= 1;
          end
        end else if (extern_pll_rst_reg || !pll_lock) begin
          pll_rst <= 1;
        end
      end

      always_ff @(posedge independent_clk) begin
        if ((counter == CNT_1 && !powerup) || (counter == CNT && reseting)) begin
          counter <= 0;
        end else if (reseting || !powerup) begin
          counter <= counter + 1'b1;
        end
      end
    end
  endgenerate

endmodule
