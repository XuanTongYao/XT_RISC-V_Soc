package XT_LBUS_Pkg;

  localparam int LB_ADDR_WIDTH = 8;
  localparam int LB_ID_WIDTH = 2;
  localparam int LB_OFFSET_WIDTH = LB_ADDR_WIDTH - LB_ID_WIDTH;  // 偏移量占用宽度
  typedef struct packed {
    logic [LB_OFFSET_WIDTH-1:0] addr;
    logic [1:0] write_width;  // 写位宽(一般只给RAM使用)
    logic [31:0] wdata;
  } lb_slave_t;


  function automatic logic [LB_OFFSET_WIDTH-1:0] LB_GetOffset(logic [LB_ADDR_WIDTH-1:0] addr);
    return addr[LB_OFFSET_WIDTH-1:0];
  endfunction

  function automatic logic [LB_ID_WIDTH-1:0] LB_GetID(logic [LB_ADDR_WIDTH-1:0] addr);
    return addr[LB_ADDR_WIDTH-1:LB_OFFSET_WIDTH];
  endfunction

endpackage
