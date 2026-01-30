// 模块: 多周期路径建模跨时钟域
// 功能: 基于MCP_Formulation的跨时钟域
//       模块本身包含了发送与接收的跨域寄存器
// 版本: v0.1
// 作者: 姚萱彤
// <<< 参 数 >>> //
// CDC_DATA_WIDTH:        跨时钟域数据位宽
//
//
// <<< 端 口 >>> //
// clk:            时钟信号
module CDC_MCP_Formulation #(
    parameter int CDC_DATA_WIDTH = 8
) (
    input clk_send,
    input rst_send,
    input send,
    output logic send_ready,
    output logic ack,

    input clk_receive,
    input rst_receive,
    input receive,
    output logic receive_ready,

    input [CDC_DATA_WIDTH-1:0] data_in,
    output logic [CDC_DATA_WIDTH-1:0] data_out
);

  logic ack_receive_tff;  // 提前声明

  //----------发送时钟域----------//
  OncePulse #(
      .DELAY(2)
  ) u_OncePulse_ack (
      .clk  (clk_send),
      .ctrl (ack_receive_tff),
      .pulse(ack)
  );
  StopAndWaitFSM #(
      .RST_READY(1)
  ) u_StopAndWaitFSM_send (
      .clk(clk_send),
      .rst(rst_send),
      .pause(send),
      .resume(ack),
      .ready(send_ready)
  );


  logic data_en_send_tff;
  always_ff @(posedge clk_send, posedge rst_send) begin
    if (rst_send) begin
      data_en_send_tff <= 0;
    end else if (send && send_ready) begin
      data_en_send_tff <= ~data_en_send_tff;
    end
  end

  logic [CDC_DATA_WIDTH-1:0] data_in_dff;
  always_ff @(posedge clk_send) begin
    if (send && send_ready) data_in_dff <= data_in;
  end



  //----------接收时钟域----------//
  wire data_en;
  OncePulse #(
      .DELAY(2)
  ) u_OncePulse_en (
      .clk  (clk_receive),
      .ctrl (data_en_send_tff),
      .pulse(data_en)
  );
  StopAndWaitFSM u_StopAndWaitFSM_receive (
      .clk(clk_receive),
      .rst(rst_receive),
      .pause(receive),
      .resume(data_en),
      .ready(receive_ready)
  );

  always_ff @(posedge clk_receive, posedge rst_receive) begin
    if (rst_receive) begin
      ack_receive_tff <= 0;
    end else if (receive && receive_ready) begin
      ack_receive_tff <= ~ack_receive_tff;
    end
  end

  // 自动接收到寄存器，直到下一次
  always_ff @(posedge clk_receive) begin
    if (data_en && !receive_ready) begin
      data_out <= data_in_dff;
    end
  end

endmodule
