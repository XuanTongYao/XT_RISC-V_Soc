// XT_HB的时钟速度hb_clk必须大于等于wb_clk_i
// 若读写同时发生则先读取再写入
// 只支持单次多写
// 读写周期可能已经优化到极限
module WISHBONE_MASTER
  import XT_BUS::*;
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
    output logic wait_finish
);

  //----------状态机----------//
  typedef enum bit [1:0] {
    IDLE  = 2'd0,
    READ  = 2'd1,
    WRITE = 2'd2
  } wishbone_state_e;
  wishbone_state_e wishbone_state;

  OncePulse #(
      .TRIGGER(2'b01)
  ) u_wc_OncePulse (
      .clk  (hb_clk),
      .ctrl (wb_ack_i),
      .pulse(wait_finish)
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
        if (hb_ready && sel.ren) begin
          wishbone_state <= READ;
        end else if (hb_ready && sel.wen) begin
          wishbone_state <= WRITE;
        end
      end
      READ: begin
        if (wb_ack_i) begin
          wishbone_state <= IDLE;
        end
      end
      WRITE: begin
        if (wb_ack_i) begin
          wishbone_state <= IDLE;
        end
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
    endcase
  end

  always_ff @(posedge wb_clk_i) begin
    if (wishbone_state == READ && wb_ack_i) begin
      rdata <= {24'b0, wb_dat_i};
    end
  end




endmodule
