package XT_LBUS_Pkg;

  localparam int LB_ADDR_WIDTH = 8;
  typedef struct packed {
    logic ren;
    logic wen;
    logic [LB_ADDR_WIDTH-1:0] addr;
    logic [1:0] write_width;  // 写位宽(一般只给RAM使用)
    logic [31:0] wdata;
  } lb_slave_t;


  // 地址匹配函数(防止忘记写)
  function automatic bit MatchWLB(lb_slave_t xt_lb, logic [LB_ADDR_WIDTH-1:0] addr);
    return xt_lb.wen && xt_lb.addr === addr;
  endfunction

  function automatic bit MatchRLB(lb_slave_t xt_lb, logic [LB_ADDR_WIDTH-1:0] addr);
    return xt_lb.ren && xt_lb.addr === addr;
  endfunction

endpackage
