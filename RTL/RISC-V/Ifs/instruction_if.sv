interface instruction_if;

  logic [31:0] addr;
  logic [31:0] inst;
  modport requestor(output addr, input inst);
  modport responder(input addr, output inst);

  // 流水线传输
  modport to_next(output addr, output inst);
  modport from_prev(input addr, input inst);

endinterface
