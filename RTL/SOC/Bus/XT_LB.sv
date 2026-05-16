module XT_LB
  import Utils_Pkg::sel_t;
(
    input rst,
    // 与高速总线桥接
    xt_hbus_device_if.port hb,

    // 低速总线部分
    xt_lbus_if.master bus
);

  logic [31:0] rdata_buffer;


  // HB时钟部分
  logic send_ready_delay, finish;
  wire send = (hb.sel.ren || hb.sel.wen) && send_ready_delay;
  wire send_ready;
  wire ack;
  always_ff @(posedge hb.clk) begin
    send_ready_delay <= send_ready;
    if (ack) begin
      hb.rdata <= rdata_buffer;
    end

    if (finish) begin
      finish <= 0;
    end else if (ack) begin
      finish <= 1;
    end
  end
  assign hb.read_finish  = finish;
  assign hb.write_finish = finish;
  localparam int TRUNCATED_WIDTH = 2 * bus.ADDR_WIDTH + 32 + 2 + 2;
  wire [TRUNCATED_WIDTH-1:0] truncated_xt_hb = {
    hb.sel.ren, hb.sel.wen, hb.raddr[bus.ADDR_WIDTH-1:0], hb.waddr[bus.ADDR_WIDTH-1:0], hb.wdata, hb.write_size
  };


  // LB时钟部分
  logic receive;
  wire receive_ready;
  wire ren, wen;
  wire [bus.ADDR_WIDTH-1:0] raddr, waddr;
  wire [31:0] wdata;
  wire [ 1:0] size;
  CDC_MCP_Formulation #(
      .CDC_DATA_WIDTH(TRUNCATED_WIDTH)
  ) u_CDC_MCP_Formulation (
      .*,
      .clk_send(hb.clk),
      .rst_send(rst),

      .clk_receive(bus.clk),
      .rst_receive(rst),

      .data_in (truncated_xt_hb),
      .data_out({ren, wen, raddr, waddr, wdata, size})
  );


  //----------状态机----------//
  typedef enum bit [1:0] {
    IDLE  = 2'd0,
    WRITE = 2'd1,
    READ  = 2'd2
  } lb_state_e;
  lb_state_e lb_state;

  wire [bus.ID_WIDTH-1:0] r_id = raddr[bus.ADDR_WIDTH-1:bus.OFFSET_WIDTH];
  wire [bus.ID_WIDTH-1:0] w_id = waddr[bus.ADDR_WIDTH-1:bus.OFFSET_WIDTH];
  always_comb begin
    bus.wsel = '{default: 1'b0};
    if (lb_state == WRITE) begin
      bus.wsel[w_id] = 1;
    end else begin
      bus.wsel = '{default: 1'b0};
    end
  end


  assign bus.wdata = wdata;
  assign bus.size  = size;
  logic read_before_write;
  always_ff @(posedge bus.clk, posedge rst) begin
    if (rst) begin
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


  always_ff @(posedge bus.clk) begin
    unique case (lb_state)
      IDLE: begin
        // 先读取后写入
        if (receive_ready && ren) begin
          bus.addr <= raddr[bus.OFFSET_WIDTH-1:0];
          read_before_write <= wen;
        end else if (receive_ready && wen) begin
          bus.addr <= waddr[bus.OFFSET_WIDTH-1:0];
        end
      end
      WRITE: ;
      READ: begin
        rdata_buffer <= bus.rdata[r_id];
        if (read_before_write) begin
          bus.addr <= waddr[bus.OFFSET_WIDTH-1:0];
        end
      end
    endcase
  end

endmodule
