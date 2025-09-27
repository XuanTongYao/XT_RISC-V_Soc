package CoreConfig;
  localparam int XLEN = 32;
  localparam int IALIGN = 32;  // 指令对齐位宽,32或16
  localparam int PC_LEN = IALIGN == 32 ? 31 : 30;
  localparam int PC_ZEROS = 32 - PC_LEN;

  function automatic logic [31:0] PadPC(logic [PC_LEN-1:0] pc);
    return {pc, {PC_ZEROS{1'b0}}};
  endfunction

endpackage
