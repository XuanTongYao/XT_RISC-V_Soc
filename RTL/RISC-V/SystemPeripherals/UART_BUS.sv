// 模块: UART通信模块
// 功能: 串口通信(不支持校验位)，取码元中心奇数个点进行判决(设N=过采样率/4，忽略前N个样本和后N+1个样本)
//       常见过采样率对应判决位:4(1,1,2), 8(2,3,3), 16(4,7,5)
//       仅支持8bit数据位，固定1bit停止位
//       收发有4字节FIFO
//       读取数据默认清空中断
// 版本: v0.5
// 作者: 姚萱彤
// <<< 参 数 >>> //
// OVER_SAMPLING:        过采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)，必须为偶数，最小为8
//
// 0:读RX寄存器   1:读状态寄存器
module UART_BUS
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
#(
    // 过采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
    parameter int OVER_SAMPLING = 16  // 必须为偶数，最小为8
) (
    input hb_clk,
    input rst,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,
    input sampling_clk,  // 过采样时钟(频率必须比总线时钟低)

    output logic rx_irq = 0,

    input uart_rx,
    output logic uart_tx
);
  localparam int unsigned SAMPLING_CNT = OVER_SAMPLING - 1;
  localparam int unsigned DECISION_START_CNT = OVER_SAMPLING / 4;
  localparam int unsigned DECISION_CNT = (OVER_SAMPLING / 2) - 1;
  localparam int unsigned DECISION_END_CNT = DECISION_START_CNT + DECISION_CNT;
  localparam int unsigned DECISION_CONDITION = (DECISION_CNT + 1) / 2;

  localparam int unsigned SAMPLING_WIDTH = $clog2(OVER_SAMPLING);
  localparam int unsigned DECISION_WIDTH = $clog2(DECISION_CNT + 1);


  //----------接收----------//
  // 时钟同步与下降沿检测
  logic sync_rx = 0;
  logic negedge_shift = 0;
  wire  negedge_detected = negedge_shift & ~sync_rx;
  always_ff @(posedge sampling_clk) begin
    sync_rx <= uart_rx;
    negedge_shift <= sync_rx;
  end

  // 状态机
  typedef enum bit [1:0] {
    IDLE = 2'd0,
    CHECK_START = 2'd1,
    RECEIVING = 2'd2,
    CHECK_STOP = 2'd3
  } rx_state_t;
  rx_state_t rx_state;

  logic [SAMPLING_WIDTH-1:0] sample_count;  // 记录每个码元的采样数
  wire symbol_end = sample_count == SAMPLING_CNT[SAMPLING_WIDTH-1:0];  // 码元结束

  logic [DECISION_WIDTH-1:0] high_sample_count;  // 用于判决的高电平样本数
  wire decision = high_sample_count >= DECISION_CONDITION[DECISION_WIDTH-1:0];  // 多数判决
  logic decision_result;  // 判决结果
  always_ff @(posedge sampling_clk) begin
    if ((rx_state == IDLE && !negedge_detected) || symbol_end) begin
      sample_count <= 0;
    end else begin
      sample_count <= sample_count + 1;
      if (sample_count == 0) begin
        high_sample_count <= 0;
      end else if (sample_count == DECISION_END_CNT[SAMPLING_WIDTH-1:0]) begin
        decision_result <= decision;
      end else if (sample_count >= DECISION_START_CNT[SAMPLING_WIDTH-1:0] && sync_rx) begin
        high_sample_count <= high_sample_count + 1;
      end
    end
  end

  logic [2:0] data_count;
  logic [7:0] rx_buffer;  // 接收缓冲区
  logic frame_end = 0;
  always_ff @(posedge sampling_clk) begin
    unique case (rx_state)
      IDLE: begin
        if (negedge_detected) rx_state <= CHECK_START;
      end
      CHECK_START: begin
        data_count <= 0;
        // 检测起始位低电平
        if (symbol_end) rx_state <= decision_result ? IDLE : RECEIVING;
      end
      RECEIVING: begin
        if (symbol_end) begin
          rx_buffer  <= {decision_result, rx_buffer[7:1]};  // 右移
          data_count <= data_count + 1;
          if (data_count == 3'd7) rx_state <= CHECK_STOP;
        end
      end
      CHECK_STOP: begin
        if (symbol_end) begin
          frame_end <= ~frame_end;
          rx_state  <= IDLE;
        end
      end
      default: rx_state <= IDLE;
    endcase
  end


  wire frame_end_pulse;
  OncePulse u_rx_OncePulse (
      .clk  (hb_clk),
      .ctrl (frame_end),
      .pulse(frame_end_pulse)
  );

  wire [7:0] rx_fifo_q;
  wire rx_full, rx_empty;
  FIFO_SC #(
      .WIDTH(8),
      .DEPTH(4)
  ) u_rx_FIFO_SC (
      .clk         (hb_clk),
      .rst         (rst),
      .wen         (frame_end_pulse),
      .ren         (sel.ren && sys_share.raddr == 'd0),
      .data        (rx_buffer),
      .q           (rx_fifo_q),
      .full        (rx_full),
      .empty       (rx_empty),
      .almost_full (),
      .almost_empty()
  );

  always_ff @(posedge hb_clk) begin
    if (frame_end_pulse) begin
      rx_irq <= 1;
    end else if (sel.ren && sys_share.raddr == 'd0) begin
      rx_irq <= 0;  // 读自动清零中断
    end
  end


  //----------发送----------//
  // 发送时钟
  wire band_clk;
  ClockDivider #(
      .DIV(OVER_SAMPLING)
  ) u_ClockDivider (
      .clk   (sampling_clk),
      .clkout(band_clk)
  );


  logic [7:0] tx_fifo_q;
  logic tx_full, tx_empty;
  logic tx_fifo_ren;
  FIFO_SC #(
      .WIDTH(8),
      .DEPTH(4)
  ) u_tx_FIFO_SC (
      .clk         (hb_clk),
      .rst         (rst),
      .wen         (sel.wen && sys_share.waddr == 'd0),
      .ren         (tx_fifo_ren),
      .data        (sys_share.wdata[7:0]),
      .q           (tx_fifo_q),
      .full        (tx_full),
      .empty       (tx_empty),
      .almost_full (),
      .almost_empty()
  );

  // 跨时钟同步
  logic tx_not_empty;
  always_ff @(posedge hb_clk) begin
    tx_not_empty <= !tx_empty;
  end


  logic copy_fifo;
  logic copy_done, copy_done_delay;
  logic [3:0] tx_symbol_count;
  logic [7:0] tx_buffer;
  always_ff @(posedge band_clk, posedge rst) begin
    if (rst) begin
      copy_done <= 0;
      uart_tx   <= 1;
    end else begin
      if (copy_done) begin
        uart_tx <= tx_buffer[0];
        if (tx_symbol_count == 4'd8) copy_done <= 0;
      end else if (copy_fifo) begin
        copy_done <= 1;
        uart_tx   <= 0;  // 发送起始位
      end
    end
  end

  always_ff @(posedge band_clk) begin
    copy_done_delay <= copy_done;
    copy_fifo <= tx_not_empty;
    if (copy_done) begin
      tx_symbol_count <= tx_symbol_count + 1;
      tx_buffer <= {1'b1, tx_buffer[7:1]};  // 从后面填充结束位并右移
    end else if (copy_fifo) begin
      tx_symbol_count <= 0;
      tx_buffer <= tx_fifo_q;
    end
  end

  OncePulse #(
      .TRIGGER(2'b01)
  ) u_tx_OncePulse (
      .clk  (hb_clk),
      .ctrl (copy_done_delay),
      .pulse(tx_fifo_ren)
  );


  //----------总线读----------//
  // 状态
  typedef struct packed {
    // 高位
    logic rx_full;       // 接收缓冲区已满
    logic tx_empty;      // 发送缓冲区空
    logic rx_not_empty;  // 接收缓冲区存在数据
    logic tx_ready;      // 发送功能已就绪（缓冲区未满）
  } uart_state_t;
  uart_state_t state;
  assign state.rx_full = rx_full;
  assign state.tx_empty = tx_empty;
  assign state.rx_not_empty = !rx_empty;
  assign state.tx_ready = !tx_full;

  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (sys_share.raddr == 'd0) begin
        rdata <= {24'b0, rx_fifo_q};
      end else begin
        rdata <= {24'b0, 4'b0, state};
      end
    end
  end

endmodule
