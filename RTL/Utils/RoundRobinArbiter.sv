module RoundRobinArbiter #(
    parameter int unsigned DEVICE_NUM = 4
) (
    input clk,
    input rst_sync,
    input [DEVICE_NUM-1:0] req,
    output logic [DEVICE_NUM-1:0] grant,
    output logic [$clog2(DEVICE_NUM)-1:0] grant_index,
    output logic busy
);
  localparam int unsigned INDEX_WIDTH = $clog2(DEVICE_NUM);
  localparam int unsigned MAX_INDEX = DEVICE_NUM - 1;

  // 仲裁选择
  logic [ DEVICE_NUM-1:0] next_grant;
  logic [INDEX_WIDTH-1:0] next_grant_index;
  always_comb begin
    int unsigned index = 0;
    next_grant = 0;
    next_grant_index = 0;
    for (int unsigned i = 1; i < DEVICE_NUM + 1; ++i) begin
      index = 32'(grant_index) + i;
      if (index >= DEVICE_NUM) begin
        index -= DEVICE_NUM;
      end
      if (req[index]) begin
        next_grant[index] = 1;
        next_grant_index  = index[INDEX_WIDTH-1:0];
        break;
      end
    end
  end


  // 轮询仲裁
  always @(posedge clk) begin
    if (rst_sync) begin
      busy <= 0;
      grant <= 0;
      grant_index <= MAX_INDEX[INDEX_WIDTH-1:0];
    end else if ((req & grant) == 0) begin
      // 等待解除占用，轮询仲裁
      if (req != 0) begin
        busy <= 1;
        grant <= next_grant;
        grant_index <= next_grant_index;
      end else begin
        busy  <= 0;
        grant <= 0;
      end
    end
  end


endmodule
