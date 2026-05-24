module RoundRobinArbiter #(
    parameter int unsigned REQ_COUNT = 4
) (
    input clk,
    input rst,
    input [REQ_COUNT-1:0] req,
    output logic [REQ_COUNT-1:0] grant,
    output logic [$clog2(REQ_COUNT)-1:0] grant_idx
);
  localparam int unsigned IDX_WIDTH = $clog2(REQ_COUNT);


  // 仲裁选择
  logic [REQ_COUNT-1:0] next_grant;
  logic [IDX_WIDTH-1:0] next_grant_index;
  always_comb begin
    int unsigned cur_idx;
    cur_idx = 32'(grant_idx);
    next_grant_index = 0;
    for (int unsigned step = 1, candidate = 0; step < REQ_COUNT + 1; ++step) begin
      candidate = cur_idx + step;
      if (candidate >= REQ_COUNT) begin
        candidate -= REQ_COUNT;
      end

      if (req[candidate]) begin
        next_grant_index = candidate[IDX_WIDTH-1:0];
        break;
      end
    end
  end

  always_comb begin
    next_grant = 0;
    next_grant[next_grant_index] = 1'b1;
  end


  // 轮询仲裁
  always @(posedge clk, posedge rst) begin
    if (rst) begin
      grant <= REQ_COUNT'(1'b1);
      grant_idx <= 0;
    end else if (req != 0 && !req[grant_idx]) begin
      // 等待解除占用，并有其他人请求，轮询仲裁
      grant <= next_grant;
      grant_idx <= next_grant_index;
    end
  end


endmodule
