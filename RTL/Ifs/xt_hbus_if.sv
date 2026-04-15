interface xt_hbus_if #(
    parameter int ADDR_WIDTH = 15,
    parameter int ID_WIDTH   = 3,
    parameter int DEVICE_NUM = 4
) (
    input clk
);
  // NOTE无法在接口中使用非压缩数组参数
  import Utils_Pkg::sel_t;
  localparam int OFFSET_WIDTH = ADDR_WIDTH - ID_WIDTH;

  logic [1:0] read_size, write_size;  // 数据大小 字节、半字、字、双字
  logic [ADDR_WIDTH-1:0] raddr, waddr;
  logic [31:0] wdata;

  sel_t device_sel[DEVICE_NUM];
  logic [31:0] device_data[DEVICE_NUM];
  logic [DEVICE_NUM-1:0] read_finish;
  logic [DEVICE_NUM-1:0] write_finish;

  modport bus(
      input clk,
      output read_size, write_size, raddr, waddr, wdata, device_sel,
      input device_data, read_finish, write_finish
  );
  modport device(
      input clk,
      input read_size, write_size, raddr, waddr, wdata, device_sel,
      output device_data, read_finish, write_finish
  );

endinterface

interface xt_hbus_device_if #(
    parameter int ID = 0,
    parameter int ADDR_WIDTH = 15
) (
    xt_hbus_if.device xt_hb
);
  import Utils_Pkg::sel_t;

  wire clk = xt_hb.clk;
  wire [1:0] read_size = xt_hb.read_size;
  wire [1:0] write_size = xt_hb.write_size;
  wire [ADDR_WIDTH-1:0] raddr = xt_hb.raddr;
  wire [ADDR_WIDTH-1:0] waddr = xt_hb.waddr;
  wire [31:0] wdata = xt_hb.wdata;
  wire sel_t sel = xt_hb.device_sel[ID];

  logic [31:0] rdata;
  logic read_finish, write_finish;
  assign xt_hb.device_data[ID]  = rdata;
  assign xt_hb.read_finish[ID]  = read_finish;
  assign xt_hb.write_finish[ID] = write_finish;
  modport port(
      input clk,
      input read_size, write_size, raddr, waddr, wdata, sel,
      output rdata, read_finish, write_finish
  );

endinterface
