// hb_clk和wb_clk_i实际上是同一个时钟
// 仅支持单次读写，有原子指令再考虑支持RMW，正在思考正确的RMW如何实现
// Q:如果有多个设备(比如DMA)要使用WISHBONE资源怎么办？
// A:给每个设备单独配一个主机，避开访问冲突问题。
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

  logic rw_finish;
  assign read_finish  = rw_finish;
  assign write_finish = rw_finish;
  always_ff @(posedge wb_clk_i) begin
    if (rw_finish) begin
      rw_finish <= 0;
    end else if (wb_ack_i && wb_stb_o) begin
      rw_finish <= 1;
    end
  end


  // 启动读写控制
  // 这里等一个周期，等HB的主机走到下一条指令
  logic hb_ready;
  wire  start_rw = hb_ready && (sel.ren || sel.wen);
  always_ff @(posedge wb_clk_i) begin
    if (wb_cyc_o) begin
      hb_ready <= 0;
    end else begin
      hb_ready <= 1;
    end
  end


  always_ff @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      wb_stb_o <= 0;
      wb_cyc_o <= 0;
    end else begin
      if (wb_cyc_o) begin  // 进行中
        if (wb_ack_i) begin
          wb_stb_o <= 0;
          wb_cyc_o <= 0;
        end
      end else if (start_rw) begin  // 空闲
        wb_stb_o <= 1;
        wb_cyc_o <= 1;
      end
    end
  end

  always_ff @(posedge wb_clk_i) begin
    if (wb_cyc_o) begin  // 进行中
      if (wb_ack_i) begin
        if (!wb_we_o) begin  // 读周期
          rdata <= {24'b0, wb_dat_i};
        end
      end
    end else if (start_rw) begin  // 空闲
      if (sel.ren) begin
        wb_we_o  <= 0;
        wb_adr_o <= xt_hb.raddr[7:0];
      end else begin
        wb_we_o  <= 1;
        wb_adr_o <= xt_hb.waddr[7:0];
        wb_dat_o <= xt_hb.wdata[7:0];
      end
    end
  end

endmodule
