// 模块: UART通信模块
// 功能: 串口通信(不支持校验位)，在码元结束边沿判决
//       仅支持8bit数据位，固定1bit停止位
//       接收有4字节FIFO
// 版本: v0.4
// 作者: 姚萱彤
// <<< 参 数 >>> //
// OVER_SAMPLING:        超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)，必须为偶数，最小为4
//
//
// <<< 端 口 >>> //
// clk:            时钟信号
// 0:读RX寄存器   1:读状态寄存器
module UART_BUS
  import XT_BUS::*;
#(
    // 超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
    parameter int OVER_SAMPLING = 16  // 必须为偶数，最小为8
) (
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,
    output logic [31:0] rdata,
    input sampling_clk,  // 超采样时钟(频率必须比总线时钟低)

    output logic rx_irq = 0,

    input uart_rx,
    output logic uart_tx = 1
);
  localparam int unsigned SAMPLING_CNT = OVER_SAMPLING - 1;
  localparam int unsigned ADJUDICATE_CNT = OVER_SAMPLING / 2;

  //----------发送时钟----------//
  wire band_clk;
  ClockDivider #(
      .DIV(OVER_SAMPLING)
  ) u_ClockDivider (
      .clk   (sampling_clk),
      .clkout(band_clk)
  );


  // 状态
  typedef struct packed {
    logic rx_fifo_full;   // 高位
    logic rx_fifo_empty;
    logic rx_end;
    logic tx_ready;
  } uart_state_t;
  uart_state_t state;
  logic tx_ready = 1;
  assign state.tx_ready = tx_ready;


  //----------接收----------//
  // 下降沿检测
  wire negedge_trigger;
  OncePulse #(
      .TRIGGER(2'b10)
  ) u_OncePulse (
      .clk  (sampling_clk),
      .ctrl (uart_rx),
      .pulse(negedge_trigger)
  );

  // 状态机
  typedef enum bit [1:0] {
    IDLE = 2'd0,
    CHECK_START = 2'd1,
    RECEIVING = 2'd2,
    CHECK_STOP = 2'd3
  } rx_state_t;
  rx_state_t rx_state;

  logic [2:0] bit_num;
  logic [7:0] rx;

  wire valid_bit = rx_state == CHECK_START ? !uart_rx : uart_rx;
  logic [$clog2(OVER_SAMPLING)-1:0] sample_cnt;
  logic [$clog2(OVER_SAMPLING)-1:0] last_valid_data_cnt;
  wire [$clog2(OVER_SAMPLING):0] valid_data_cnt = last_valid_data_cnt + valid_bit;
  wire adjudicating = sample_cnt == SAMPLING_CNT;
  wire adjudicate_result = valid_data_cnt >= ADJUDICATE_CNT;

  always_ff @(posedge sampling_clk) begin
    unique case (rx_state)
      IDLE: begin
        bit_num <= 0;
        if (negedge_trigger && !uart_rx) rx_state <= CHECK_START;
      end
      CHECK_START: begin
        if (adjudicating) begin
          if (adjudicate_result) begin
            rx_state <= RECEIVING;
          end else begin
            rx_state <= IDLE;
          end
        end
      end
      RECEIVING: begin
        if (adjudicating) begin
          rx <= {adjudicate_result, rx[7:1]};
          bit_num <= bit_num + 1'b1;
          if (bit_num == 3'd7) rx_state <= CHECK_STOP;
        end
      end
      CHECK_STOP: begin
        if (adjudicating) rx_state <= IDLE;
      end
    endcase
  end


  // 采样
  always_ff @(posedge sampling_clk) begin
    if (rx_state == IDLE) begin
      if (negedge_trigger && !uart_rx) begin
        last_valid_data_cnt <= 2'd2;
        sample_cnt <= 2'd2;
      end
    end else begin
      if (adjudicating) begin
        sample_cnt <= 0;
        last_valid_data_cnt <= 0;
      end else begin
        sample_cnt <= sample_cnt + 1'b1;
        last_valid_data_cnt <= valid_data_cnt;
      end
    end
  end

  logic [7:0] rx_fifo[4];
  logic [1:0] rx_wr_ptr, rx_rd_ptr;
  logic [2:0] rx_fifo_count;
  assign state.rx_fifo_full = rx_fifo_count == 4;
  assign state.rx_fifo_empty = rx_fifo_count == 0;
  assign state.rx_end = !state.rx_fifo_empty;
  wire rx_end_pulse;
  OncePulse #(
      .TRIGGER(2'b10)
  ) u_rx_OncePulse (
      .clk  (hb_clk),
      .ctrl (rx_state == CHECK_STOP),
      .pulse(rx_end_pulse)
  );
  always_ff @(posedge hb_clk) begin
    if (rx_end_pulse && !state.rx_fifo_full) begin
      rx_fifo[rx_wr_ptr] <= rx;
      rx_wr_ptr <= rx_wr_ptr + 1;
      rx_fifo_count <= rx_fifo_count + 1;
      rx_irq <= 1;
    end else if (sel.ren && xt_hb.raddr[5:2] == 5'd9 && !state.rx_fifo_empty) begin
      rx_rd_ptr <= rx_rd_ptr + 1;
      rx_fifo_count <= rx_fifo_count - 1;
      rx_irq <= 0;
    end
  end


  //----------发送----------//
  logic [7:0] tx;
  always_ff @(posedge hb_clk) begin
    if (sel.wen && xt_hb.waddr[5:2] == 5'd9) begin
      tx <= xt_hb.wdata[7:0];
    end
  end

  // 使用移位寄存器代替计数器实现LUT优化
  logic [9:0] shift_reg = 10'b000000000_1;
  logic copy_done = 0;
  logic [8:0] tx_copy;
  wire send_stop_bit = shift_reg[9];
  always_ff @(posedge band_clk) begin
    if (!tx_ready) begin
      if (copy_done) begin
        shift_reg <= {shift_reg[8:0], shift_reg[9]};
        tx_copy   <= {1'b1, tx_copy[8:1]};  // 从后面填充结束位
        uart_tx   <= tx_copy[0];
        if (send_stop_bit) copy_done <= 0;
      end else begin
        tx_copy   <= {tx, 1'b0};
        copy_done <= 1'b1;
      end
    end
  end

  // 旧的实现
  // wire [9:0] tx_vec = {1'b1, tx, 1'b0};// 插入起始位与结束位
  // logic [3:0] tx_ptr = 0;
  // wire send_stop_bit = tx_ptr == 4'd9;
  // always_ff @(posedge band_clk) begin
  //   if (!state.tx_ready) begin
  //     if (send_stop_bit) begin
  //       tx_ptr <= 0;
  //     end else begin
  //       tx_ptr <= tx_ptr + 1'b1;
  //     end
  //     uart_tx <= tx_vec[tx_ptr];
  //   end
  // end


  wire tx_ready_pulse;
  OncePulse #(
      .TRIGGER(2'b10)
  ) u_tx_OncePulse (
      .clk  (hb_clk),
      .ctrl (send_stop_bit),
      .pulse(tx_ready_pulse)
  );
  always_ff @(posedge hb_clk) begin
    if (sel.wen) begin
      tx_ready <= 0;
    end else if (tx_ready_pulse) begin
      tx_ready <= 1;
    end
  end


  //----------总线读----------//
  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (xt_hb.raddr[5:2] == 5'd9) begin
        rdata <= {24'b0, rx_fifo[rx_rd_ptr]};
      end else begin
        rdata <= {24'b0, 4'b0, state};
      end
    end
  end

endmodule
