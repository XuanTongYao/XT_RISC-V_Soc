// 寄存器布局
// 0 display_data
// 1 ledsd_control
module LEDSD_Direct_LBUS #(
    parameter bit E_CODE = 0,
    parameter bit COM = 0,
    parameter int NUM = 2
) (
    xt_lbus_slave_if.port lb,
    output logic [8:0] ledsd[NUM]
);

  typedef struct packed {
    logic [NUM-1:0] dig;
    logic [NUM-1:0] dp;
  } ledsd_control_t;
  ledsd_control_t ledsd_control;

  logic [7:0] display_data;
  always_ff @(posedge lb.clk) begin
    if (lb.wen) begin
      if (lb.addr[0] == 'd0) begin
        display_data <= lb.wdata[7:0];
      end else begin
        ledsd_control <= lb.wdata[(2*NUM)-1:0];
      end
    end
  end


  always_comb begin
    if (lb.addr[0] == 'd0) begin
      lb.rdata = 8'(display_data);
    end else begin
      lb.rdata = 8'(ledsd_control);
    end
  end


  LEDSD_Direct #(
      .E_CODE(E_CODE),
      .COM   (COM),
      .NUM   (NUM)
  ) u_LEDSD_Direct (
      .data_in({display_data}),
      .dig    ({ledsd_control.dig}),
      .dp     ({ledsd_control.dp}),
      .ledsd  (ledsd)
  );

endmodule
