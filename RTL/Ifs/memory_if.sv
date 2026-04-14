interface memory_direct_if #(
    int DATA_WIDTH = 32,
    int ADDR_WIDTH = 32
);

  logic read, write;
  logic [1:0] read_size, write_size;  // 访问的大小 字节、半字、字、双字
  logic [ADDR_WIDTH-1:0] raddr, waddr;
  logic [DATA_WIDTH-1:0] rdata, wdata;
  modport master(output read, write, read_size, write_size, raddr, waddr, wdata, input rdata);
  modport slave(input read, write, read_size, write_size, raddr, waddr, wdata, output rdata);

endinterface
