// XT_HB的时钟速度hb_clk必须大于等于wb_clk_i
// 若读写同时发生则进行RMW
// 只支持单次读写与RMW
// 读写周期可能已经优化到极限
module WISHBONE_MASTER
  import Utils_Pkg::sel_t;
  import XT_HBUS_Pkg::*;
#(
    parameter int PORT_SIZE = 8
) (
    // 与总线控制器
    input wb_clk_i,
    input wb_rst_i,

    // 与从设备
    input wb_ack_i,
    input [PORT_SIZE-1:0] wb_dat_i,
    output logic [PORT_SIZE-1:0] wb_dat_o,
    output logic wb_cyc_o,
    output logic wb_stb_o,
    output logic wb_we_o,
    output logic [PORT_SIZE-1:0] wb_adr_o,

    // 与XT_HB总线
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,
    output logic [31:0] rdata,
    // 停止等待
    output logic read_finish,
    output logic write_finish
);

  //----------状态机----------//
  typedef enum bit [1:0] {
    IDLE  = 2'd0,
    READ  = 2'd1,
    WRITE = 2'd2,
    RWM   = 2'd3
  } wishbone_state_e;
  wishbone_state_e wishbone_state;

  logic ready_ack, rw_finish;
  assign read_finish  = rw_finish;
  assign write_finish = rw_finish;
  OncePulse #(
      .TRIGGER(2'b01)
  ) u_wc_OncePulse (
      .clk  (hb_clk),
      .ctrl (wb_ack_i && ready_ack),
      .pulse(rw_finish)
  );
  // 启动读写控制
  // 把这里的信号换成一个设备准备信号
  // 访问WISHBONE前一定会有一个周期执行其他指令,hb_ready初始值会被置1
  logic hb_ready;
  always_ff @(posedge hb_clk) begin
    if (wishbone_state == IDLE) begin
      hb_ready <= 1;
    end else if (wishbone_state == WRITE || wishbone_state == READ) begin
      hb_ready <= 0;
    end
  end

  always_ff @(posedge wb_clk_i) begin
    unique case (wishbone_state)
      IDLE: begin
        // 先读取再写入
        if (hb_ready) begin
          if (sel.ren && sel.wen) begin
            ready_ack <= 0;
            wishbone_state <= READ;
          end else if (sel.ren) begin
            ready_ack <= 1;
            wishbone_state <= READ;
          end else if (sel.wen) begin
            ready_ack <= 1;
            wishbone_state <= WRITE;
          end
        end
      end
      READ: begin
        if (wb_ack_i) begin
          rdata <= {24'b0, wb_dat_i};
          if (ready_ack) begin
            wishbone_state <= IDLE;
          end else begin
            wishbone_state <= RWM;
          end
        end
      end
      WRITE: begin
        if (wb_ack_i) begin
          wishbone_state <= IDLE;
        end
      end
      RWM: begin
        ready_ack <= 1;
        wishbone_state <= WRITE;
      end
      default: ;
    endcase
  end

  always_comb begin
    wb_adr_o = xt_hb.waddr[7:0];
    wb_we_o  = 0;
    wb_stb_o = 0;
    wb_cyc_o = 0;
    wb_dat_o = xt_hb.wdata[7:0];
    unique case (wishbone_state)
      IDLE: ;
      READ: begin
        wb_adr_o = xt_hb.raddr[7:0];
        wb_stb_o = 1;
        wb_cyc_o = 1;
      end
      WRITE: begin
        wb_adr_o = xt_hb.waddr[7:0];
        wb_we_o  = 1;
        wb_stb_o = 1;
        wb_cyc_o = 1;
      end
      RWM: begin
        wb_cyc_o = 1;
      end
    endcase
  end


endmodule
