module XT_LB
  import XT_BUS::*;
#(
    parameter int SLAVE_NUM = 4
) (
    // 与高速总线桥接
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,
    output logic [31:0] rdata,

    // 低速总线部分
    input lb_clk,
    input [31:0] lb_data_in[SLAVE_NUM],
    output lb_slave_t bus = 0,
    output logic wait_finish
);

  logic [31:0] rdata_mux;
  always_comb begin
    rdata_mux = 0;
    for (int i = 0; i < SLAVE_NUM; i++) begin
      rdata_mux = rdata_mux | lb_data_in[i];  // 逐个或运算
    end
  end

  logic lb_ack = 0;
  localparam int TRUNCATED_WIDTH = 2 * LB_ADDR_WIDTH + 32 + 2 + 2;
  wire [TRUNCATED_WIDTH-1:0] truncated_xt_hb = {
    sel.ren, sel.wen, xt_hb.raddr[LB_ADDR_WIDTH-1:0], xt_hb.waddr[LB_ADDR_WIDTH-1:0], xt_hb.wdata, xt_hb.write_width
  };
  wire ren, wen;
  wire [LB_ADDR_WIDTH-1:0] raddr, waddr;
  wire [31:0] wdata;
  wire [1:0] write_width;
  wire hb_ready;
  wire waiting_slow_domain;
  ClockDomainCrossing #(
      .CDC_DFF_NUM(TRUNCATED_WIDTH)
  ) u_ClockDomainCrossing (
      .fast_clk           (hb_clk),
      .data_enable        (sel.ren || sel.wen),
      .ack                (lb_ack),
      .data_in            (truncated_xt_hb),
      .data_out           ({ren, wen, raddr, waddr, wdata, write_width}),
      .data_valid         (hb_ready),
      .waiting_slow_domain(waiting_slow_domain)
  );
  assign wait_finish = !waiting_slow_domain;


  //----------状态机----------//
  typedef enum bit [1:0] {
    IDLE  = 2'd0,
    WRITE = 2'd1,
    READ  = 2'd2
  } lb_state_e;
  lb_state_e lb_state;


  always_ff @(posedge lb_clk) begin
    unique case (lb_state)
      IDLE: begin
        // 先写入再读取
        if (hb_ready && wen) begin
          lb_state        <= WRITE;
          bus.wen         <= 1;
          bus.addr        <= waddr;
          bus.wdata       <= wdata;
          bus.write_width <= write_width;
        end else if (hb_ready && ren) begin
          lb_state <= READ;
          bus.ren  <= 1;
          bus.addr <= raddr;
        end
      end
      WRITE: begin
        bus.wen <= 0;
        if (ren) begin
          lb_state <= READ;
          bus.ren  <= 1;
          bus.addr <= raddr;
        end else begin
          lb_state <= IDLE;
          lb_ack   <= ~lb_ack;
        end
      end
      READ: begin
        lb_state <= IDLE;
        lb_ack <= ~lb_ack;
        rdata <= rdata_mux;
        bus.ren <= 0;
      end
    endcase
  end

endmodule
