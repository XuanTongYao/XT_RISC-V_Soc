// 寄存器布局
// 0 display_data
// 1 ledsd_control
module LEDSD_Direct_LBUS #(
    parameter bit COM = 0,
    parameter int NUM = 2
) (
    xt_lbus_if.port lb,
    output logic [8:0] ledsd[NUM]
);

  typedef struct packed {
    logic [NUM-1:0] dig;
    logic [NUM-1:0] dp;
  } ledsd_control_t;
  ledsd_control_t ledsd_control;

  logic [(4*NUM)-1:0] display_data;
  always_ff @(posedge lb.clk) begin
    if (lb.wen) begin
      if (lb.addr[0] == 'd0) begin
        display_data <= lb.wdata[$bits(display_data)-1:0];
      end else begin
        ledsd_control <= lb.wdata[$bits(ledsd_control)-1:0];
      end
    end
  end


  always_comb begin
    if (lb.addr[0] == 'd0) begin
      lb.rdata = 32'(display_data);
    end else begin
      lb.rdata = 32'(ledsd_control);
    end
  end

  logic [3:0] data_in[NUM];
  logic dig[NUM];
  logic dp[NUM];
  always_comb begin
    for (int i = 0; i < NUM; ++i) begin
      data_in[NUM-i-1] = display_data[(i*4)+:4];
      dig[NUM-i-1] = ledsd_control.dig[i];
      dp[NUM-i-1] = ledsd_control.dp[i];
    end
  end

  LEDSD_Direct #(
      .E_CODE(0),
      .COM   (COM),
      .NUM   (NUM)
  ) u_LEDSD_Direct (
      .data_in(data_in),
      .dig    (dig),
      .dp     (dp),
      .ledsd  (ledsd)
  );

endmodule
