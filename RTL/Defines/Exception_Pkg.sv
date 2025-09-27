package Exception_Pkg;
  //----------同步异常原因代码----------//
  localparam int USED_CODE_LEN = 5;
  localparam bit [USED_CODE_LEN-1:0] INST_ADDR_MISALIGNED = 'd0;
  localparam bit [USED_CODE_LEN-1:0] INST_ACCESS_FAULT = 'd1;
  localparam bit [USED_CODE_LEN-1:0] ILLEGAL_INST = 'd2;
  localparam bit [USED_CODE_LEN-1:0] BREAKPOINT = 'd3;
  localparam bit [USED_CODE_LEN-1:0] LOAD_ADDRESS_MISALIGNED = 'd4;
  localparam bit [USED_CODE_LEN-1:0] LOAD_ACCESS_FAULT = 'd5;
  localparam bit [USED_CODE_LEN-1:0] STORE_AMO_ADDRESS_MISALIGNED = 'd6;
  localparam bit [USED_CODE_LEN-1:0] STORE_AMO_ACCESS_FAULT = 'd7;
  localparam bit [USED_CODE_LEN-1:0] ECALL_FROM_U_MODE = 'd8;
  localparam bit [USED_CODE_LEN-1:0] ECALL_FROM_S_MODE = 'd9;
  //   localparam bit [USED_CODE_LEN-1:0] RESERVED = 'd10;
  localparam bit [USED_CODE_LEN-1:0] ECALL_FROM_M_MODE = 'd11;
  localparam bit [USED_CODE_LEN-1:0] INST_PAGE_FAULT = 'd12;
  localparam bit [USED_CODE_LEN-1:0] LOAD_PAGE_FAULT = 'd13;
  //   localparam bit [USED_CODE_LEN-1:0] RESERVED = 'd14;
  localparam bit [USED_CODE_LEN-1:0] STORE_AMO_PAGE_FAULT = 'd15;
  localparam bit [USED_CODE_LEN-1:0] DOUBLE_TRAP = 'd16;
  //   localparam bit [USED_CODE_LEN-1:0] RESERVED = 'd17;
  localparam bit [USED_CODE_LEN-1:0] SOFTWARE_CHECK = 'd18;
  localparam bit [USED_CODE_LEN-1:0] HARDWARE_ERROR = 'd19;


  //----------标准中断原因代码----------//
  //   localparam bit [30:0] SUPERVISOR_SOFTWARE_INT = 31'd1;
  localparam bit [30:0] MACHINE_SOFTWARE_INT = 31'd3;
  //   localparam bit [30:0] SUPERVISOR_TIMER_INT = 31'd5;
  localparam bit [30:0] MACHINE_TIMER_INT = 31'd7;
  //   localparam bit [30:0] SUPERVISOR_EXTERNAL_INT = 31'd9;
  localparam bit [30:0] MACHINE_EXTERNAL_INT = 31'd11;
  localparam bit [30:0] COUNTER_OVERFLOW_INT = 31'd13;


  //----------类型定义----------//
  typedef struct packed {
    logic raise;
    logic [USED_CODE_LEN-1:0] code;
  } exception_t;


  //----------实用函数----------//
  function automatic logic [30:0] PadExceptionCode(logic [USED_CODE_LEN-1:0] code);
    return {{(31 - USED_CODE_LEN) {1'b0}}, code};
  endfunction

endpackage


