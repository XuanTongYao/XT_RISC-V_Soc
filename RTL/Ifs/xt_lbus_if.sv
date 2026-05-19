interface xt_lbus_if #(
    int OFFSET_WIDTH = 6
);

  wire clk, rst;
  wire [OFFSET_WIDTH-1:0] addr;
  wire [1:0] size;  // 数据大小 字节、半字、字、双字
  wire [31:0] wdata;
  wire wen;

  logic [31:0] rdata;
  modport bus(output clk, rst, output addr, size, wdata, wen, input rdata);
  modport port(input clk, rst, input addr, size, wdata, wen, output rdata);

endinterface
