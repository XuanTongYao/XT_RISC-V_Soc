// 模块: 简易时钟监控器
// 功能: 监控PLL锁定情况，自动复位或响应外部复位信号
//       在电源稳定前拉高PLL复位
//       若在最大锁定周期到达时，未能成功锁定，尝试重新复位锁定
// 版本: v0.2
// 作者: 姚萱彤
// <<< 参 数 >>> //
// MAX_LOCK_PERIOD:     最大锁定周期(相对于独立时钟)
// POWER_ON_PERIOD:      电源稳定周期(相对于独立时钟)，为0则禁用
//
//
// <<< 端 口 >>> //
// independent_clk:     独立时钟信号
// extern_pll_rst:      外部复位信号
// pll_lock:            PLL锁定情况
// pll_rst:             PLL复位输出
module ClockMonitor #(
    parameter int MAX_LOCK_PERIOD = 360_000,
    parameter int POWER_ON_PERIOD = 12_000_000
) (
    input independent_clk,
    input extern_pll_rst,
    input pll_lock,
    output logic pll_rst
);
  localparam int MAX_PERIOD = POWER_ON_PERIOD >= MAX_LOCK_PERIOD ? POWER_ON_PERIOD : MAX_LOCK_PERIOD;
  localparam int WIDTH = $clog2(MAX_PERIOD);
  localparam int CNT = MAX_LOCK_PERIOD - 1;
  localparam int CNT_1 = POWER_ON_PERIOD - 1;

  logic extern_pll_rst_reg;
  logic extern_pll_rst_sync;
  logic pll_lock_reg;
  logic pll_lock_sync;
  always_ff @(posedge independent_clk) begin
    extern_pll_rst_reg <= extern_pll_rst;
    extern_pll_rst_sync <= extern_pll_rst_reg;
    pll_lock_reg <= pll_lock;
    pll_lock_sync <= pll_lock_reg;
  end

  // pll_rst要持续1ns，肯定满足要求
  logic reseting = 0;
  logic [WIDTH-1:0] counter;
  generate
    if (POWER_ON_PERIOD == 0) begin : gen_normal_check
      always_ff @(posedge independent_clk) begin
        if (reseting) begin
          counter <= counter + 1;
          if (counter == CNT) begin
            reseting <= 0;
            if (!pll_lock_sync) pll_rst <= 1;  // 尝试重新复位
          end
        end else if (pll_rst && !extern_pll_rst_sync) begin
          counter  <= 0;
          pll_rst  <= 0;
          reseting <= 1;
        end else if (extern_pll_rst_sync || !pll_lock_sync) begin
          pll_rst <= 1;
        end
      end

    end else begin : gen_wait_power_on_check
      logic power_on = 0;
      logic power_stable;
      always_ff @(posedge independent_clk) begin
        if (!power_on) begin
          power_stable <= 0;
          counter <= 0;
          power_on <= 1;
          pll_rst <= 1;
        end else if (!power_stable) begin
          counter <= counter + 1;
          if (counter == CNT_1) power_stable <= 1;
        end else if (reseting) begin
          counter <= counter + 1;
          if (counter == CNT) begin
            reseting <= 0;
            if (!pll_lock_sync) pll_rst <= 1;  // 尝试重新复位
          end
        end else if (pll_rst && !extern_pll_rst_sync) begin
          counter  <= 0;
          pll_rst  <= 0;
          reseting <= 1;
        end else if (extern_pll_rst_sync || !pll_lock_sync) begin
          pll_rst <= 1;
        end
      end
    end
  endgenerate

endmodule
