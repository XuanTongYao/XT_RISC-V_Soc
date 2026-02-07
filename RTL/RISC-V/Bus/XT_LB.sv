module XT_LB
  import Utils_Pkg::sel_t;
  import XT_HBUS_Pkg::*;
  import XT_LBUS_Pkg::*;
#(
    parameter int SLAVE_NUM = 4
) (
    // 与高速总线桥接
    input hb_clk,
    input rst_sync,
    input hb_slave_t xt_hb,
    input sel_t sel,
    output logic [31:0] rdata,

    // 低速总线部分
    input lb_clk,
    input [31:0] lb_data_in[SLAVE_NUM],
    output lb_slave_t bus,
    output logic lb_wsel[SLAVE_NUM],
    output logic read_finish,
    output logic write_finish
);

  logic [31:0] rdata_buffer;


  // HB时钟部分
  logic send_ready_delay, finish;
  wire send = (sel.ren || sel.wen) && send_ready_delay;
  wire send_ready;
  wire ack;
  always_ff @(posedge hb_clk) begin
    send_ready_delay <= send_ready;
    if (ack) begin
      rdata <= rdata_buffer;
    end

    if (finish) begin
      finish <= 0;
    end else if (ack) begin
      finish <= 1;
    end
  end
  assign read_finish  = finish;
  assign write_finish = finish;
  localparam int TRUNCATED_WIDTH = 2 * LB_ADDR_WIDTH + 32 + 2 + 2;
  wire [TRUNCATED_WIDTH-1:0] truncated_xt_hb = {
    sel.ren, sel.wen, xt_hb.raddr[LB_ADDR_WIDTH-1:0], xt_hb.waddr[LB_ADDR_WIDTH-1:0], xt_hb.wdata, xt_hb.write_width
  };


  // LB时钟部分
  logic receive;
  wire receive_ready;
  wire ren, wen;
  wire [LB_ADDR_WIDTH-1:0] raddr, waddr;
  wire [31:0] wdata;
  wire [ 1:0] write_width;
  CDC_MCP_Formulation #(
      .CDC_DATA_WIDTH(TRUNCATED_WIDTH)
  ) u_CDC_MCP_Formulation (
      .*,
      .clk_send(hb_clk),
      .rst_send(rst_sync),

      .clk_receive(lb_clk),
      .rst_receive(rst_sync),

      .data_in (truncated_xt_hb),
      .data_out({ren, wen, raddr, waddr, wdata, write_width})
  );


  //----------状态机----------//
  typedef enum bit [1:0] {
    IDLE  = 2'd0,
    WRITE = 2'd1,
    READ  = 2'd2
  } lb_state_e;
  lb_state_e lb_state;

  wire [LB_ID_WIDTH-1:0] r_id = LB_GetID(raddr);
  wire [LB_ID_WIDTH-1:0] w_id = LB_GetID(waddr);
  logic wsel[SLAVE_NUM];
  always_comb begin
    wsel = '{default: 1'b0};
    wsel[w_id] = 1;
  end
  assign lb_wsel = lb_state == WRITE ? wsel : '{default: 1'b0};


  assign bus.wdata = wdata;
  assign bus.write_width = write_width;
  logic read_before_write;
  always_ff @(posedge lb_clk, posedge rst_sync) begin
    if (rst_sync) begin
      lb_state <= IDLE;
      receive  <= 0;
    end else begin
      unique case (lb_state)
        IDLE: begin
          // 先读取后写入
          if (receive_ready && ren) begin
            lb_state <= READ;
            receive  <= ~wen;
          end else if (receive_ready && wen) begin
            lb_state <= WRITE;
            receive  <= 1;
          end
        end
        WRITE: begin
          lb_state <= IDLE;
          receive  <= 0;
        end
        READ: begin
          if (read_before_write) begin
            lb_state <= WRITE;
            receive  <= 1;
          end else begin
            lb_state <= IDLE;
            receive  <= 0;
          end
        end
      endcase
    end
  end


  always_ff @(posedge lb_clk) begin
    unique case (lb_state)
      IDLE: begin
        // 先读取后写入
        if (receive_ready && ren) begin
          bus.addr <= LB_GetOffset(raddr);
          read_before_write <= wen;
        end else if (receive_ready && wen) begin
          bus.addr <= LB_GetOffset(waddr);
        end
      end
      WRITE: ;
      READ: begin
        rdata_buffer <= lb_data_in[r_id];
        if (read_before_write) begin
          bus.addr <= LB_GetOffset(waddr);
        end
      end
    endcase
  end

endmodule
