// 用于核心内部的接口
interface csr_rw_if #(
    int DATA_LEN = 32
);
  import CSR_Pkg::csr_addr_t;

  logic ren, wen;
  csr_addr_t addr;
  logic [DATA_LEN-1:0] wdata, rdata;
  modport core(output ren, wen, addr, wdata, input rdata);
  modport csr(input ren, wen, addr, wdata, output rdata);
endinterface

interface reg_r_if #(
    int DATA_LEN = 32
);
  logic [4:0] addr;
  logic [DATA_LEN-1:0] data;
  modport core(output addr, input data);
  modport regs(input addr, output data);
endinterface

interface reg_w_if #(
    int DATA_LEN = 32
);
  logic en;
  logic [4:0] addr;
  logic [DATA_LEN-1:0] data;
  modport core(output en, addr, data);
  modport regs(input en, addr, data);
endinterface

interface exception_if;
  import Exception_Pkg::USED_CODE_LEN;
  logic raise;
  logic [USED_CODE_LEN-1:0] code;
  modport source(output raise, code);
  modport observer(input raise, code);
endinterface

interface id_to_ex_if #(
    int XLEN = 32
);

  logic load, store;
  logic [XLEN-1:0] load_addr, store_addr;
  logic [XLEN-1:0] store_data;
  logic [XLEN-1:0] operand1, operand2;
  logic reg_wen;
  modport to_next(output load, store, load_addr, store_addr, store_data, operand1, operand2, reg_wen);
  modport from_prev(input load, store, load_addr, store_addr, store_data, operand1, operand2, reg_wen);

endinterface

interface trap_if #(
    int XLEN   = 32,
    int PC_LEN = 30
);
  import CSR_Pkg::*;
  mstatus_t mstatus;
  mie_m_only_t mie;
  mip_m_only_t mip;
  mtvec_t mtvec;
  logic [PC_LEN-1:0] mepc;

  logic occurred, returned;
  logic [XLEN-1:0] jump_addr;
  mcause_t new_mcause;
  logic [PC_LEN-1:0] new_mepc;

  wire any_int_come = (mie & mip) != 0;
  logic valid_int_req;
  modport controller(
      output valid_int_req, occurred, jump_addr, new_mcause, new_mepc,
      input mstatus, mie, mip, mtvec, any_int_come
  );
  modport csr(input occurred, returned, new_mepc, new_mcause, output mstatus, mie, mip, mtvec, mepc);
  modport core_controller(input any_int_come, valid_int_req, occurred, jump_addr);
  modport execute(input mepc, output returned);
endinterface

interface debug_if #(
    int PC_LEN = 30
);
  import CSR_Pkg::dcsr_only_sdext_t;
  logic halted;  // 处于调试模式
  logic halt, resume;
  logic [2:0] new_cause;
  logic [PC_LEN-1:0] new_dpc;

  logic [PC_LEN-1:0] dpc;
  dcsr_only_sdext_t dcsr;

  logic bypass_wfi, valid_haltreq;
  modport controller(output halted, halt, resume, new_cause, new_dpc, bypass_wfi, valid_haltreq, input dcsr, dpc);
  modport csr(input halted, halt, new_cause, new_dpc, output dcsr, dpc);
  modport core(input halted, halt, bypass_wfi, valid_haltreq, resume, dcsr, dpc);
endinterface
