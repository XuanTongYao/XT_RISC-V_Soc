package CSR_Typedefs;

  typedef struct packed {
    logic sd;
    logic [7:0] wpri_3;
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
    logic [15:0] wpri;
    logic [3:0] zero_6;
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
    logic [15:0] wpri;
    logic [3:0] zero_6;
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


endpackage

