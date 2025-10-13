package CSR_Pkg;

  localparam bit [1:0] READONLY = 2'b11;

  typedef enum bit [1:0] {
    USER = 2'b00,
    SUPERVISOR = 2'b01,
    HYPERVISOR = 2'b10,
    MACHINE = 2'b11
  } privilege_levels_t;

  typedef struct packed {
    logic sd;
    logic [5:0] wpri_3;
    logic sdt;
    logic spelp;
    logic tsr;
    logic tw;
    logic tvm;
    logic mxr;
    logic sum;
    logic mprv;
    logic [1:0] xs;
    logic [1:0] fs;
    logic [1:0] mpp;
    logic [1:0] vs;
    logic spp;
    logic mpie;
    logic ube;
    logic spie;
    logic wpri_2;
    logic mie;
    logic wpri_1;
    logic sie;
    logic wpri_0;
  } mstatus_t;

  typedef struct packed {
    logic [25:0] wpri_1;
    logic mbe;
    logic sbe;
    logic [3:0] wpri_0;
  } mstatush_t;

  typedef struct packed {
    logic [29:0] base;
    logic [1:0]  mode;
  } mtvec_t;

  typedef struct packed {
    logic [15:0] custom;
    logic [1:0] zero_7;
    logic lcofip;
    logic zero_6;
    logic meip;
    logic zero_5;
    logic seip;
    logic zero_4;
    logic mtip;
    logic zero_3;
    logic stip;
    logic zero_2;
    logic msip;
    logic zero_1;
    logic ssip;
    logic zero_0;
  } mip_t;

  typedef struct packed {
    logic [15:0] custom;
    logic [1:0] zero_7;
    logic lcofie;
    logic zero_6;
    logic meie;
    logic zero_5;
    logic seie;
    logic zero_4;
    logic mtie;
    logic zero_3;
    logic stie;
    logic zero_2;
    logic msie;
    logic zero_1;
    logic ssie;
    logic zero_0;
  } mie_t;

  typedef struct packed {
    logic interrupt;
    logic [30:0] code;
  } mcause_t;


  //----------简化结构体----------//
  typedef struct packed {
    logic meip;
    logic mtip;
    logic msip;
  } mip_m_only_t;

  typedef struct packed {
    logic meie;
    logic mtie;
    logic msie;
  } mie_m_only_t;

  function automatic logic [31:0] PadMieMip(logic [2:0] mip_mie);
    logic eip_eie;
    logic tip_tie;
    logic sip_sie;
    eip_eie = mip_mie[2];
    tip_tie = mip_mie[1];
    sip_sie = mip_mie[0];
    return {20'b0, eip_eie, 3'b0, tip_tie, 3'b0, sip_sie, 3'b0};
  endfunction

endpackage

