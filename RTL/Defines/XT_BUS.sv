package XT_BUS;

  // XT_HB的地址，高位是识别符，低位是偏移量，基地址在识别符上对齐
  // 只使用一个识别符的设备，地址偏移量可以直接作为访问地址使用
  // 使用多个识别符的设备，用完整地址减去基地址作为访问地址使用
  `define ADDR_WIDTH 14
  `define ID_WIDTH 3
  localparam int HB_ADDR_WIDTH = `ADDR_WIDTH;  // 总线可寻址位宽(必须比RAM位宽大)
  localparam int HB_ID_WIDTH = `ID_WIDTH;  // 识别符占用宽度
  localparam int HB_OFFSET_WIDTH = HB_ADDR_WIDTH - HB_ID_WIDTH;  // 偏移量占用宽度

  typedef struct packed {
    logic [`ADDR_WIDTH-1:0] raddr, waddr;
    logic [31:0] wdata;
    logic [1:0] write_width;  // 写位宽(一般只给RAM使用)
  } hb_slave_t;

  // 主机输入高速总线
  typedef struct packed {
    logic [1:0] write_width;
    logic read;
    logic write;
    logic [`ADDR_WIDTH-1:0] raddr, waddr;
    logic [31:0] wdata;
  } hb_master_in_t;

  // 读写片选
  typedef struct packed {
    logic ren;
    logic wen;
  } sel_t;


  `define LB_ADDR_WIDTH 8
  localparam int LB_ADDR_WIDTH = `LB_ADDR_WIDTH;
  typedef struct packed {
    logic ren;
    logic wen;
    logic [`LB_ADDR_WIDTH-1:0] addr;
    logic [31:0] wdata;
    logic [1:0] write_width;  // 写位宽(一般只给RAM使用)
  } lb_slave_t;


  // 地址匹配函数(防止忘记写)
  function automatic bit MatchWLB(lb_slave_t xt_lb, logic [LB_ADDR_WIDTH-1:0] addr);
    return xt_lb.wen && xt_lb.addr === addr;
  endfunction

  function automatic bit MatchRLB(lb_slave_t xt_lb, logic [LB_ADDR_WIDTH-1:0] addr);
    return xt_lb.ren && xt_lb.addr === addr;
  endfunction

endpackage
