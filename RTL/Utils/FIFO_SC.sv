// 仅支持2的幂的深度，最小深度为4
// 可选show-ahead模式
// 强制使用溢出保护
// 几乎要满/空阈值必须介于1~DEPTH之间，否则不启用
// 大于等于几乎要满阈值时置位almost_full
// 小于等于几乎要空阈值时置位almost_empty
module FIFO_SC #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 4,
    parameter bit SHOW_AHEAD = 1,
    parameter int ALMOST_FULL_THRESHOLD = 0,
    parameter int ALMOST_EMPTY_THRESHOLD = 0
) (
    input clk,
    input rst,
    input wen,
    input ren,
    input [WIDTH-1:0] data,
    output logic [WIDTH-1:0] q,
    output logic almost_full,
    output logic full,
    output logic almost_empty,
    output logic empty

);
  localparam int TRUE_DEPTH = DEPTH <= 4 ? 4 : 1 << $clog2(DEPTH);
  localparam int PTR_WIDTH = $clog2(TRUE_DEPTH);

  logic [PTR_WIDTH-1:0] write_ptr, read_ptr;
  logic [PTR_WIDTH:0] count;
  logic [  WIDTH-1:0] fifo  [TRUE_DEPTH];

  //----------写----------//
  assign full = count == TRUE_DEPTH[PTR_WIDTH:0];
  wire write_vaild = wen && !full;
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      write_ptr <= 0;
    end else if (write_vaild) begin
      write_ptr <= write_ptr + 1;
      fifo[write_ptr] <= data;
    end
  end


  //----------读----------//
  assign empty = count == 0;
  wire read_vaild = ren && !empty;
  wire [PTR_WIDTH-1:0] next_read_ptr = read_ptr + 1;
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      read_ptr <= 0;
    end else if (read_vaild) begin
      read_ptr <= next_read_ptr;
    end
  end

  generate
    if (SHOW_AHEAD) begin : g_show_ahead
      always_ff @(posedge clk) begin
        if (empty) begin
          if (wen) begin
            q <= data;
          end
        end else if (read_vaild) begin
          q <= fifo[next_read_ptr];
        end
      end
    end else begin : g_normal
      always_ff @(posedge clk) begin
        if (read_vaild) begin
          q <= fifo[read_ptr];
        end
      end
    end
  endgenerate


  //----------计数----------//
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      count <= 0;
    end else if (write_vaild && !read_vaild) begin
      count <= count + 1;
    end else if (!write_vaild && read_vaild) begin
      count <= count - 1;
    end
  end

  generate
    if (0 < ALMOST_FULL_THRESHOLD && ALMOST_FULL_THRESHOLD <= TRUE_DEPTH) begin : g_almost_full
      assign almost_full = count >= ALMOST_FULL_THRESHOLD[PTR_WIDTH:0];
    end else begin : g_non_almost_full
      assign almost_full = 0;
    end
  endgenerate

  generate
    if (0 < ALMOST_EMPTY_THRESHOLD && ALMOST_EMPTY_THRESHOLD <= TRUE_DEPTH) begin : g_almost_empty
      assign almost_empty = count <= ALMOST_EMPTY_THRESHOLD[PTR_WIDTH:0];
    end else begin : g_non_almost_empty
      assign almost_empty = 0;
    end
  endgenerate


endmodule
