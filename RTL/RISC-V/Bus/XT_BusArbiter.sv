//----------总线仲裁器----------//
// 轮询仲裁器
module XT_BusArbiter #(
    parameter int DEVICE_NUM = 4
) (
    input clk,
    input [DEVICE_NUM-1:0] read_req,
    input [DEVICE_NUM-1:0] write_req,
    output logic [DEVICE_NUM-1:0] read_accept,
    output logic [DEVICE_NUM-1:0] write_accept,
    output logic read_busy,
    output logic write_busy
);
  localparam int INDEX_WIDTH = $clog2(DEVICE_NUM);

  generate
    if (DEVICE_NUM == 1) begin : gen_exclusive
      assign read_accept[0] = 1'b1;
      assign write_accept[0] = 1'b1;
      assign read_busy = 1;
      assign write_busy = 1;
    end else begin : gen_polling
      logic [INDEX_WIDTH-1:0] read_polling_index = 0;
      logic [INDEX_WIDTH-1:0] write_polling_index = 0;
      logic [INDEX_WIDTH-1:0] reading_index = 0;
      logic [INDEX_WIDTH-1:0] writing_index = 0;
      logic [ DEVICE_NUM-1:0] read_accept_on_index;
      logic [ DEVICE_NUM-1:0] write_accept_on_index;
      always_comb begin
        for (int i = 0; i < DEVICE_NUM; ++i) begin
          read_accept_on_index[i]  = read_polling_index == i;
          write_accept_on_index[i] = write_polling_index == i;
        end
      end

      // 死锁自动重置
      logic dead_locked = read_busy && write_busy && (reading_index != writing_index) && read_req[writing_index] &&
          write_req[reading_index];


      always_ff @(posedge clk) begin
        if (dead_locked) begin
          read_busy <= 0;
          read_accept <= 0;
          read_polling_index <= 0;
        end else if (read_busy) begin
          // 被占用，等待解除占用
          if (!read_req[reading_index]) begin
            if (read_req[read_polling_index]) begin
              // 立刻切换仲裁
              read_busy <= 1;
              read_accept <= read_accept_on_index;
              reading_index <= read_polling_index;
            end else begin
              read_busy   <= 0;
              read_accept <= 0;
              if (read_polling_index == DEVICE_NUM - 1) begin
                read_polling_index <= 0;
              end else begin
                read_polling_index <= read_polling_index + 1'b1;
              end
            end
          end
        end else begin
          // 没有被占用，轮询仲裁
          if (read_req[read_polling_index]) begin
            read_busy <= 1;
            read_accept <= read_accept_on_index;
            reading_index <= read_polling_index;
          end
          if (read_polling_index == DEVICE_NUM - 1) begin
            read_polling_index <= 0;
          end else begin
            read_polling_index <= read_polling_index + 1'b1;
          end
        end
      end

      always_ff @(posedge clk) begin
        if (dead_locked) begin
          write_busy <= 0;
          write_accept <= 0;
          write_polling_index <= 0;
        end else if (write_busy) begin
          // 被占用，等待解除占用
          if (!write_req[writing_index]) begin
            if (write_req[write_polling_index]) begin
              // 立刻切换仲裁
              write_busy <= 1;
              write_accept <= write_accept_on_index;
              writing_index <= write_polling_index;
            end else begin
              write_busy   <= 0;
              write_accept <= 0;
              if (write_polling_index == DEVICE_NUM - 1) begin
                write_polling_index <= 0;
              end else begin
                write_polling_index <= write_polling_index + 1'b1;
              end
            end
          end
        end else begin
          // 没有被占用，轮询仲裁
          if (write_req[write_polling_index]) begin
            write_busy <= 1;
            write_accept <= write_accept_on_index;
            writing_index <= write_polling_index;
          end
          if (write_polling_index == DEVICE_NUM - 1) begin
            write_polling_index <= 0;
          end else begin
            write_polling_index <= write_polling_index + 1'b1;
          end
        end
      end

    end
  endgenerate


endmodule
