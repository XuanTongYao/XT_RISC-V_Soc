interface jtag_if;
  logic tck, tms, tdi, tdo, n_reset;
  modport probe(output tck, tms, tdi, n_reset, input tdo);
  modport dtm(input tck, tms, tdi, n_reset, output tdo);
endinterface

interface dmi_if #(
    parameter int unsigned ABITS = 7
);

  logic             req_valid;
  logic             req_ready;
  logic [ABITS-1:0] req_addr;
  logic [     31:0] req_data;
  logic [      1:0] req_op;

  logic             rsp_valid;
  logic             rsp_ready;
  logic [     31:0] rsp_data;
  logic [      1:0] rsp_op;

  modport dtm(output req_valid, req_addr, req_data, req_op, rsp_ready, input req_ready, rsp_valid, rsp_data, rsp_op);
  modport dm(input req_valid, req_addr, req_data, req_op, rsp_ready, output req_ready, rsp_valid, rsp_data, rsp_op);

endinterface

interface dm_hart_minimal_if;
  import Debug_Pkg::hart_dm_state_t;
  logic havereset  /* hart复位成功粘滞位 */, ackhavereset;
  logic haltreq, resumereq;
  hart_dm_state_t dm_state;  // hart调试状态
  modport dm(output ackhavereset, haltreq, resumereq, input havereset, dm_state);
  modport hart(input ackhavereset, haltreq, resumereq, output havereset, dm_state);
endinterface

interface dm_register_if;

  logic [2:0] aarsize;
  logic transfer, write;
  logic [15:0] regno;  // 寄存器编号
  logic [31:0] wdata;

  logic [31:0] rdata;
  logic completed, failed;

  modport dm(output aarsize, transfer, write, regno, wdata, input rdata, completed, failed);
  modport hart(input aarsize, transfer, write, regno, wdata, output rdata, completed, failed);

endinterface
