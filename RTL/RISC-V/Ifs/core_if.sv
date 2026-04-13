// 用于核心内部的接口
interface csr_rw_if;
  import CSR_Pkg::csr_addr_t;

  logic ren;
  logic wen;
  csr_addr_t addr;
  logic [31:0] wdata;
  logic [31:0] rdata;

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

interface memory_access_if #(
    int XLEN = 32
);

  logic load, store;
  logic [XLEN-1:0] load_addr, store_addr;
  logic [XLEN-1:0] store_data;
  modport to_next(output load, store, load_addr, store_addr, store_data);
  modport from_prev(input load, store, load_addr, store_addr, store_data);

endinterface

