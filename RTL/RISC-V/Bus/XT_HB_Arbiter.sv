module XT_HB_Arbiter #(
    parameter int DEVICE_NUM = 4
) (
    input clk,
    input rst_sync,
    input [DEVICE_NUM-1:0] read_req,
    input [DEVICE_NUM-1:0] write_req,
    output logic [DEVICE_NUM-1:0] read_grant,
    output logic [DEVICE_NUM-1:0] write_grant,
    output logic read_busy,
    output logic write_busy
);
  localparam int INDEX_WIDTH = $clog2(DEVICE_NUM);

  generate
    if (DEVICE_NUM == 1) begin : gen_exclusive
      assign read_grant[0] = 1'b1;
      assign write_grant[0] = 1'b1;
      assign read_busy = 1;
      assign write_busy = 1;
    end else begin : gen_polling
      wire [INDEX_WIDTH-1:0] reading_index;
      wire [INDEX_WIDTH-1:0] writing_index;

      // 死锁自动重置
      wire dead_locked = read_busy && write_busy && (reading_index != writing_index) && read_req[writing_index] &&
          write_req[reading_index];
      wire rst_arbiter = dead_locked || rst_sync;

      RoundRobinArbiter #(
          .DEVICE_NUM(DEVICE_NUM)
      ) u_ReadArbiter (
          .*,
          .rst_sync   (rst_arbiter),
          .req        (read_req),
          .grant      (read_grant),
          .grant_index(reading_index),
          .busy       (read_busy)
      );

      RoundRobinArbiter #(
          .DEVICE_NUM(DEVICE_NUM)
      ) u_WriteArbiter (
          .*,
          .rst_sync   (rst_arbiter),
          .req        (write_req),
          .grant      (write_grant),
          .grant_index(writing_index),
          .busy       (write_busy)
      );

    end
  endgenerate


endmodule
