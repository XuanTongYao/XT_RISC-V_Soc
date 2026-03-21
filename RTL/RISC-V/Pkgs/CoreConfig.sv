package CoreConfig;

  // 原始配置参数
  typedef struct packed {
    bit Z;  // 保留
    bit Y;  // 保留
    bit X;  // 未实现
    bit W;  // 保留
    bit V;  // 未实现
    bit U;  // 未实现
    bit T;  // 保留
    bit S;  // 未实现
    bit R;  // 保留
    bit Q;  // 未实现
    bit P;  // 未实现
    bit O;  // 保留
    bit N;  // 未实现
    bit M;  // 未实现
    bit L;  // 保留
    bit K;  // 保留
    bit J;  // 保留
    bit I;  // 未实现
    bit H;  // 未实现
    bit G;  // 保留
    bit F;  // 未实现
    bit E;  // E嵌入式指令集
    bit D;  // 未实现
    bit C;  // 未实现
    bit B;  // 未实现
    bit A;  // 未实现
  } extension_cfg_t;

  typedef struct packed {
    int XLEN;  // 位宽
    extension_cfg_t EXTENSION;  // 扩展
  } core_raw_cfg_t;

  typedef enum bit [1:0] {
    XLEN32 = 2'd1,
    XLEN64 = 2'd2
  } xl_t;

  // 配置参数(已计算相关值)
  typedef struct packed {
    int XLEN;  // 位宽
    extension_cfg_t EXTENSION;  // 扩展
    xl_t MXL;
    int REG_NUMS;
    int REG_LEN;

    int IALIGN;    // 指令对齐位宽,32或16
    int PC_LEN;
    int PC_ZEROS;
  } core_cfg_t;

  function automatic core_cfg_t ComputeCoreCfg(core_raw_cfg_t raw_cfg);
    extension_cfg_t EXTENSION = raw_cfg.EXTENSION;
    int XLEN = raw_cfg.XLEN;
    core_cfg_t cfg = '{default: 0};
    cfg.XLEN = XLEN;
    cfg.EXTENSION = EXTENSION;
    cfg.MXL = XLEN == 32 ? XLEN32 : XLEN64;
    cfg.REG_NUMS = EXTENSION.E ? 16 : 32;
    cfg.REG_LEN = $clog2(cfg.REG_NUMS);
    cfg.IALIGN = EXTENSION.C ? 16 : 32;
    cfg.PC_LEN = cfg.IALIGN == 32 ? XLEN - 2 : XLEN - 1;
    cfg.PC_ZEROS = XLEN - cfg.PC_LEN;
    return cfg;
  endfunction

  // 默认配置参数
  localparam core_raw_cfg_t CORE_RAW_DEFAULT_CFG = '{EXTENSION: '{default: 0}, XLEN: 32};
  localparam core_cfg_t CORE_DEFAULT_CFG = ComputeCoreCfg(CORE_RAW_DEFAULT_CFG);


  function automatic logic [63:0] PadPC(logic [63:0] pc, int ZEROS);
    return pc << ZEROS;
  endfunction

endpackage
