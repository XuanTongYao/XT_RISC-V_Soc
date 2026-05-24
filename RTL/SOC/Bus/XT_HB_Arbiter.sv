module XT_HB_Arbiter #(
    parameter int unsigned REQ_COUNT = 4,
    localparam int unsigned REQ_IDX_WIDTH = (REQ_COUNT == 1) ? 1 : $clog2(REQ_COUNT)
) (
    input clk,
    input rst,
    input [REQ_COUNT-1:0] read_req,
    input [REQ_COUNT-1:0] write_req,
    output logic [REQ_COUNT-1:0] read_grant,
    output logic [REQ_COUNT-1:0] write_grant,
    output logic [REQ_IDX_WIDTH-1:0] read_grant_idx,
    output logic [REQ_IDX_WIDTH-1:0] write_grant_idx
);

  generate
    if (REQ_COUNT == 1) begin : gen_exclusive
      assign read_grant = 1'b1;
      assign write_grant = 1'b1;
      assign read_grant_idx = 0;
      assign write_grant_idx = 0;
    end else begin : gen_polling

      wire rst_sync = rst;
      RoundRobinArbiter #(
          .REQ_COUNT(REQ_COUNT)
      ) u_ReadArbiter (
          .*,
          .req      (read_req),
          .grant    (read_grant),
          .grant_idx(read_grant_idx)
      );

      RoundRobinArbiter #(
          .REQ_COUNT(REQ_COUNT)
      ) u_WriteArbiter (
          .*,
          .req      (write_req),
          .grant    (write_grant),
          .grant_idx(write_grant_idx)
      );

    end
  endgenerate


endmodule
