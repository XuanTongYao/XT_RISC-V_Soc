interface xt_lbus_if #(
    int ADDR_WIDTH = 8,
    int ID_WIDTH   = 2,
    int SLAVE_NUM  = 4
) (
    input lb_clk
);
  localparam int OFFSET_WIDTH = ADDR_WIDTH - ID_WIDTH;

  logic [OFFSET_WIDTH-1:0] addr;
  logic [1:0] size;  // 数据大小 字节、半字、字、双字
  logic [31:0] wdata;
  logic wsel[SLAVE_NUM];
  logic [31:0] rdata[SLAVE_NUM];
  wire clk = lb_clk;

  modport master(input clk, output addr, size, wdata, wsel, input rdata);
  modport slave(input clk, input addr, size, wdata, wsel, output rdata);

endinterface

interface xt_lbus_slave_if #(
    int ID = 0,
    int OFFSET_WIDTH = 6
) (
    xt_lbus_if.slave xt_lb
);

  wire clk = xt_lb.clk;
  wire [OFFSET_WIDTH-1:0] addr = xt_lb.addr;
  wire [1:0] size = xt_lb.size;
  wire [31:0] wdata = xt_lb.wdata;

  wire wen = xt_lb.wsel[ID];
  logic [31:0] rdata;
  assign xt_lb.rdata[ID] = rdata;
  modport port(input clk, input addr, size, wdata, wen, output rdata);

endinterface
