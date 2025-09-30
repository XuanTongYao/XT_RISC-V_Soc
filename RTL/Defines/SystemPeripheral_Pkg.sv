package SystemPeripheral_Pkg;
  import Utils_Pkg::sel_t;

  import XT_HBUS_Pkg::HB_ADDR_WIDTH;
  import XT_HBUS_Pkg::HB_OFFSET_WIDTH;

  localparam int SP_ADDR_LEN = 5;
  localparam int SP_ID_LEN = 3;
  localparam int SP_OFFSET_LEN = SP_ADDR_LEN - SP_ID_LEN;

  typedef struct packed {
    logic [SP_OFFSET_LEN-1:0] raddr, waddr;
    logic [31:0] wdata;
  } sys_peripheral_t;

  function automatic logic [HB_OFFSET_WIDTH-1:0] GetOffset(logic [HB_ADDR_WIDTH-1:0] addr);
    return addr[HB_OFFSET_WIDTH-1:0];
  endfunction

  function automatic bit RAddrEq(sys_peripheral_t sys, logic [SP_OFFSET_LEN-1:0] addr);
    return sys.raddr === addr;
  endfunction

  function automatic bit WAddrEq(sys_peripheral_t sys, logic [SP_OFFSET_LEN-1:0] addr);
    return sys.waddr === addr;
  endfunction

  // 真实操了蛋了，Synplify Pro不支持export
  // So, Synplify Pro FUCK YOU!
  // export Utils_Pkg::sel_t;
endpackage
