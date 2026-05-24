interface xt_hbus_if #(
    int ADDR_WIDTH = 16
);

  wire clk, rst;

  wire [1:0] read_size, write_size;
  wire [ADDR_WIDTH-1:0] raddr, waddr;
  wire [31:0] wdata;

  wire ren, wen;  // 读写片选
  logic [31:0] rdata;
  logic read_finish, write_finish;
  modport bus(
      output clk, rst,
      output ren, wen, read_size, write_size, raddr, waddr, wdata,
      input rdata, read_finish, write_finish
  );
  modport port(
      input clk, rst,
      input ren, wen, read_size, write_size, raddr, waddr, wdata,
      output rdata, read_finish, write_finish
  );

endinterface

interface xt_hbus_rsp_if;
  wire read_grant, write_grant, read_stall, write_stall, stall_req;
  modport bus(output read_grant, write_grant, read_stall, write_stall, stall_req);
  modport master(input read_grant, write_grant, read_stall, write_stall, stall_req);
endinterface

// 寄存器强制对齐到32bit的总线适配器，提供更好的性能
// 每个从设备仅能占用一个ID
// 所有从设备必须能在一个时钟周期内完成写入
// 在两个时钟周期内完成读取并锁存数据
interface xt_hbus32_if #(
    int OFFSET_WIDTH = 5
);

  wire clk, rst;

  wire [OFFSET_WIDTH-1:0] raddr, waddr;
  wire [31:0] wdata;

  wire ren, wen;  // 读写片选
  logic [31:0] rdata;
  modport bus(output clk, rst, output ren, wen, raddr, waddr, wdata, input rdata);
  modport port(input clk, rst, input ren, wen, raddr, waddr, wdata, output rdata);

endinterface
