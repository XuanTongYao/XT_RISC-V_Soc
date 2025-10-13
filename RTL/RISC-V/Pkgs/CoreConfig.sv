package CoreConfig;
  //----------扩展支持----------//
  localparam bit EXT_M = 0;  // 未实现
  localparam bit EXT_A = 0;  // 未实现
  localparam bit EXT_F = 0;  // 未实现
  localparam bit EXT_D = 0;  // 未实现
  localparam bit EXT_C = 0;  // 未实现


  //----------基础设置----------//
  localparam int XLEN = 32;
  localparam int IALIGN = EXT_C ? 16 : 32;  // 指令对齐位宽,32或16
  localparam int PC_LEN = IALIGN == 32 ? 31 : 30;
  localparam int PC_ZEROS = 32 - PC_LEN;

  function automatic logic [31:0] PadPC(logic [PC_LEN-1:0] pc);
    return {pc, {PC_ZEROS{1'b0}}};
  endfunction

endpackage
