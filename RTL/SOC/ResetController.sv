// ResetController和ResetWishboneOverride都是为了解决MXO2芯片的一个问题:
// 开启Flash接口时全局复位(GSR)会被禁用
// 此模块整合了PLL脱锁自动复位+恢复GSR
module ResetController #(
    parameter int MAX_LOCK_PERIOD = 360_000
) (
    input independent_clk,
    input pll_lock,
    output logic pll_rst,

    wishbone_syscon_if.port syscon,
    wishbone_if.master wb,
    input wb_idle,
    output logic wb_override,

    input reset_req,
    output logic reset
);
  localparam int WIDTH = $clog2(MAX_LOCK_PERIOD);
  localparam int CNT = MAX_LOCK_PERIOD - 1;


  // PLL脱锁自动复位检测
  logic [1:0] pll_lock_sync;
  logic pll_reseting = 0;
  logic [WIDTH-1:0] lock_counter;
  assign pll_rst = !pll_lock && !pll_reseting;
  always_ff @(posedge independent_clk) begin
    pll_lock_sync <= {pll_lock_sync[0], pll_lock};

    if (pll_reseting) begin
      if (lock_counter == CNT[WIDTH-1:0]) pll_reseting <= 0;
      else lock_counter <= lock_counter + 'd1;
    end else if (!pll_lock_sync[1]) begin
      lock_counter <= 0;
      pll_reseting <= 1;
    end
  end



  // 关闭Flash接口以恢复GSR并设置复位
  // 最高位为1表示写入0x71, 否则写入0x70
  localparam bit [8:0] COMMAND_STRING[9] = '{
      {1'b0, 8'h40},  // 复位
      {1'b0, 8'h80},  // 开始命令
      {1'b1, 8'h26},
      {1'b1, 8'h00},
      {1'b1, 8'h00},  // Disable
      {1'b0, 8'h00},  // 结束命令
      {1'b0, 8'h80},  // 开始命令
      {1'b1, 8'hFF},  // Bypass
      {1'b0, 8'h00}  // 结束命令
  };
  logic [3:0] ptr;

  logic perform;
  wire ack;
  wire [wb.PORT_SIZE-1:0] wdata = COMMAND_STRING[ptr][7:0];
  wire [wb.PORT_SIZE-1:0] addr = {4'h7, 3'b0, COMMAND_STRING[ptr][8]};
  WISHBONE_MASTER #(
      .PORT_SIZE(wb.PORT_SIZE)
  ) u_WISHBONE_MASTER (
      .*,
      .perform(perform),
      .write(1'b1),
      .rdata(),
      .write_mode()
  );

  typedef enum bit [1:0] {
    PENDING = 2'd0,
    COMMAND = 2'd1,
    ASSERT_RESET = 2'd2,
    RELEASE = 2'd3
  } reset_state_e;
  reset_state_e reset_state;
  assign perform = reset_state == COMMAND;

  logic reset_pending;
  always_ff @(posedge syscon.clk, negedge pll_lock) begin
    if (!pll_lock) begin
      reset_state   <= PENDING;
      wb_override   <= 1;
      reset_pending <= 1;
    end else begin
      unique case (reset_state)
        PENDING: begin
          if (reset_req) reset_pending <= 1;
          if (reset_pending && (wb_idle || wb_override)) begin
            ptr <= 0;
            wb_override <= 1;
            reset_state <= COMMAND;
          end
        end
        COMMAND: begin
          if (ack) begin
            if (ptr == 4'd8) begin
              reset_state <= ASSERT_RESET;
            end else begin
              ptr <= ptr + 'd1;
            end
          end
        end
        ASSERT_RESET: begin
          reset <= 1;
          reset_state <= RELEASE;
        end
        RELEASE: begin
          if (!reset_req) begin
            reset <= 0;
            reset_pending <= 0;
            wb_override <= 0;
            reset_state <= PENDING;
          end
        end
      endcase
    end
  end
endmodule
