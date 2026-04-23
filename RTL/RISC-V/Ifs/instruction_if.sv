interface instruction_if #(
    int XLEN = 32
);

  logic enable;  // 仅用于指令存储器
  logic [XLEN-1:0] addr;
  logic [31:0] inst;
  modport requestor(output addr, enable, input inst);
  modport responder(input addr, enable, output inst);

  // 流水线传输
  modport to_next(output addr, output inst);
  modport from_prev(input addr, input inst);

endinterface
