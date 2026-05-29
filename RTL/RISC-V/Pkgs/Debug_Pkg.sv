package Debug_Pkg;

  //----------自设的结构体----------//
  typedef enum bit [1:0] {
    NONEXISTENT = 2'd0,
    UNAVAIL = 2'd1,  // 因复位或其他原因halt暂时不可用
    RUNNING = 2'd2,
    HALTED = 2'd3
  } hart_dm_state_t;


  //----------标准调试原因代码----------//
  // 按优先级排列的 其中RESETHALTREQ优先级最高
  localparam bit [2:0] DEBUG_RESETHALTREQ = 'd5;
  localparam bit [2:0] DEBUG_HALT_GROUP = 'd6;
  localparam bit [2:0] DEBUG_HALTREQ = 'd3;
  localparam bit [2:0] DEBUG_TRIGGER = 'd2;
  localparam bit [2:0] DEBUG_EBREAK = 'd1;
  localparam bit [2:0] DEBUG_STEP = 'd4;


  //----------DTM寄存器----------//
  typedef struct packed {
    logic [10:0] zero_11;
    logic [2:0] errinfo;
    logic dtmhardreset;
    logic dmireset;
    logic zero_1;
    logic [2:0] idle;
    logic [1:0] dmistat;
    logic [5:0] abits;
    logic [3:0] version;
  } dtmcs_t;


  //----------DM寄存器----------//
  localparam bit [6:0] DM_DATA_BASE = 7'h04;

  localparam bit [6:0] DM_DMCONTROL = 7'h10;
  typedef struct packed {
    logic       haltreq;
    logic       resumereq;
    logic       hartreset;
    logic       ackhavereset;
    logic       ackunavail;
    logic       hasel;
    logic [9:0] hartsello;
    logic [9:0] hartselhi;
    logic       setkeepalive;
    logic       clrkeepalive;
    logic       setresethaltreq;
    logic       clrresethaltreq;
    logic       ndmreset;
    logic       dmactive;
  } dmcontrol_t;

  typedef struct packed {
    // 单个hart的最小裁减版本(hasel=0,hartsel=0)
    // 无独立hartreset复位(hartreset=0)
    // hart始终对调试器可用(set/clr keepalive=0)
    // 不实现resethaltreq(set/clr resethaltreq=0)
    // 非粘性unavail(写入ackunavail无效)
    // 仅写入有效：haltreq,resumereq,ackhavereset
    logic ndmreset;
    logic dmactive;
  } dmcontrol_minimal_t;
  function automatic dmcontrol_t PadDmcontrol(dmcontrol_minimal_t partially);
    dmcontrol_t fully;
    fully = '{ndmreset: partially.ndmreset, dmactive: partially.dmactive, default: 0};
    return fully;
  endfunction


  localparam bit [6:0] DM_DMSTATUS = 7'h11;
  typedef struct packed {
    logic [6:0] zero_7;
    logic       ndmresetpending;
    logic       stickyunavail;
    logic       impebreak;
    logic [1:0] zero_2;
    logic       allhavereset;
    logic       anyhavereset;
    logic       allresumeack;
    logic       anyresumeack;
    logic       allnonexistent;
    logic       anynonexistent;
    logic       allunavail;
    logic       anyunavail;
    logic       allrunning;
    logic       anyrunning;
    logic       allhalted;
    logic       anyhalted;
    logic       authenticated;
    logic       authbusy;
    logic       hasresethaltreq;
    logic       confstrptrvalid;
    logic [3:0] version;
  } dmstatus_t;
  typedef struct packed {
    // 单个hart的最小裁减版本(all/any都精简到any,
    //  any havereset=havereset,any resumeack=resumeack,
    //  any nonexistent=0,any unavail=unavail,
    //  any running=running,any halted=halted)
    //
    // 不监控ndmreset状态(ndmresetpending=0)
    // 非粘性unavail(stickyunavail=0)
    // 无程序缓冲区(impebreak=0)
    // 无身份验证(authenticated=1,authbusy=0)
    // 不实现resethaltreq(hasresethaltreq=0)
    // 无配置结构体指针(confstrptrvalid=0)
    logic anyhavereset;
    logic anyresumeack;
    logic anyunavail;
    logic anyrunning;
    logic anyhalted;
  } dmstatus_minimal_t;
  function automatic dmstatus_t PadDmstatus(dmstatus_minimal_t partially);
    dmstatus_t fully;
    fully = '{
        allhavereset: partially.anyhavereset,
        anyhavereset: partially.anyhavereset,
        allresumeack: partially.anyresumeack,
        anyresumeack: partially.anyresumeack,
        allunavail: partially.anyunavail,
        anyunavail: partially.anyunavail,
        allrunning: partially.anyrunning,
        anyrunning: partially.anyrunning,
        allhalted: partially.anyhalted,
        anyhalted: partially.anyhalted,
        authenticated: 1'b1,
        version: 4'd3,
        default: 0
    };
    return fully;
  endfunction


  localparam bit [6:0] DM_ABSTRACTCS = 7'h16;
  typedef enum bit [2:0] {
    ERR_NONE = 3'd0,
    ERR_BUSY = 3'd1,
    ERR_NOT_SUPPORTED = 3'd2,
    ERR_EXCEPTION = 3'd3,
    ERR_HALT_OR_RESUME = 3'd4,
    ERR_BUS = 3'd5,
    ERR_RESERVED = 3'd6,
    ERR_OTHER = 3'd7
  } cmderr_t;
  typedef struct packed {
    logic [2:0]  zero_3;
    logic [4:0]  progbufsize;
    logic [10:0] zero_11;
    logic        busy;
    logic        relaxedpriv;
    logic [2:0]  cmderr;
    logic [3:0]  zero_4;
    logic [3:0]  datacount;
  } abstractcs_t;
  typedef struct packed {
    // 可变数据
    logic       busy;
    logic       relaxedpriv;
    logic [2:0] cmderr;
  } abstractcs_variable_t;
  function automatic abstractcs_t PadAbstractcs(abstractcs_variable_t variable, logic [4:0] progbufsize,
                                                logic [3:0] datacount);
    abstractcs_t fully;
    fully = '{
        progbufsize: progbufsize,
        datacount: datacount,
        busy: variable.busy,
        relaxedpriv: variable.relaxedpriv,
        cmderr: variable.cmderr,
        default: 0
    };
    return fully;
  endfunction

  localparam bit [6:0] DM_COMMAND = 7'h17;
  typedef enum bit [7:0] {
    ACCESS_REGISTER = 8'd0,
    QUICK_ACCESS = 8'd1,
    ACCESS_MEMORY = 8'd2
  } cmdtype_t;
  typedef struct packed {
    logic [7:0]  cmdtype;
    logic [23:0] control;
  } command_t;

  localparam bit [15:0] CSR_NO_BASE = 16'h0000;
  localparam bit [15:0] GPR_NO_BASE = 16'h1000;
  localparam bit [15:0] FPR_NO_BASE = 16'h1020;
  typedef struct packed {
    logic        zero_1;
    logic [2:0]  aarsize;
    logic        aarpostincrement;
    logic        postexec;
    logic        transfer;
    logic        write;
    logic [15:0] regno;
  } command_access_register_t;

  typedef struct packed {
    logic        aamvirtual;
    logic [2:0]  aamsize;
    logic        aampostincrement;
    logic [1:0]  zero_2;
    logic        write;
    logic [1:0]  target_specific;
    logic [13:0] zero_14;
  } command_access_memory_t;

  localparam bit [6:0] DM_SBCS = 7'h38;
  typedef struct packed {
    logic [2:0] sbversion;
    logic [5:0] zero_6;
    logic       sbbusyerror;
    logic       sbbusy;
    logic       sbreadonaddr;
    logic [2:0] sbaccess;
    logic       sbautoincrement;
    logic       sbreadondata;
    logic [2:0] sberror;
    logic [6:0] sbasize;
    logic       sbaccess128;
    logic       sbaccess64;
    logic       sbaccess32;
    logic       sbaccess16;
    logic       sbaccess8;
  } sbcs_t;

endpackage
