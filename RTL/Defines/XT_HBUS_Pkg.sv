package XT_HBUS_Pkg;
  import Utils_Pkg::sel_t;

  // XT_HB的地址，高位是识别符，低位是偏移量，基地址在识别符上对齐
  // 只使用一个识别符的设备，地址偏移量可以直接作为访问地址使用
  // 使用多个识别符的设备，用完整地址减去基地址作为访问地址使用
  localparam int HB_ADDR_WIDTH = 15;  // 总线可寻址位宽(必须比RAM位宽大)
  localparam int HB_ID_WIDTH = 3;  // 识别符占用宽度
  localparam int HB_OFFSET_WIDTH = HB_ADDR_WIDTH - HB_ID_WIDTH;  // 偏移量占用宽度

  typedef struct packed {
    logic [HB_ADDR_WIDTH-1:0] raddr, waddr;
    logic [31:0] wdata;
    logic [1:0] write_width;  // 写位宽(一般只给RAM使用)
  } hb_slave_t;

  // 主机输入高速总线
  typedef struct packed {
    logic [1:0] write_width;
    logic read;
    logic write;
    logic [HB_ADDR_WIDTH-1:0] raddr, waddr;
    logic [31:0] wdata;
  } hb_master_in_t;


  function automatic logic [HB_OFFSET_WIDTH-1:0] HB_GetOffset(logic [HB_ADDR_WIDTH-1:0] addr);
    return addr[HB_OFFSET_WIDTH-1:0];
  endfunction

  function automatic logic [HB_ID_WIDTH-1:0] HB_GetID(logic [HB_ADDR_WIDTH-1:0] addr);
    return addr[HB_ADDR_WIDTH-1:HB_OFFSET_WIDTH];
  endfunction

  // So, Synplify Pro FUCK YOU!
  // export Utils_Pkg::sel_t;
endpackage
