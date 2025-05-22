module ClockMonitor #(
    parameter int MAX_LOCK_PERIOD = 360_000,
    parameter int POWERUP_PERIOD  = 12_000_000
) (
    input independent_clk,
    input extern_pll_rst,
    input pll_lock,
    output logic pll_rst = 1
);
  localparam int WIDTH = $clog2(POWERUP_PERIOD);
  localparam int CNT = MAX_LOCK_PERIOD - 1;
  localparam int CNT_1 = POWERUP_PERIOD - 1;

  logic extern_pll_rst_reg;
  always_ff @(posedge independent_clk) begin
    extern_pll_rst_reg <= extern_pll_rst;
  end

  // pll_rst要持续1ns，肯定满足要求
  logic powerup = 0;
  logic reseting = 0;
  logic [WIDTH-1:0] cnt_lock = 0;
  always_ff @(posedge independent_clk) begin
    if (!powerup) begin
      if (cnt_lock == CNT_1) begin
        powerup <= 1;
      end else begin
        pll_rst <= 1;
      end
    end else if (reseting) begin
      if (cnt_lock == CNT && pll_lock) begin
        reseting <= 0;
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
    if ((cnt_lock == CNT_1 && !powerup) || (cnt_lock == CNT && powerup)) begin
      cnt_lock <= 0;
    end else if (reseting || !powerup) begin
      cnt_lock <= cnt_lock + 1'b1;
    end
  end


endmodule
