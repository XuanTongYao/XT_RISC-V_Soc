package CoreConfig;

  // 原始配置参数
  typedef struct packed {
    bit Z;  // 保留
    bit Y;  // 保留
    bit X;  // 存在非标准扩展
    bit W;  // 保留
    bit V;  // 当前未实现 向量扩展
    bit U;  // 当前未实现 U 模式
    bit T;  // 保留
    bit S;  // 当前未实现 S 模式
    bit R;  // 保留
    bit Q;  // 当前未实现 四精度浮点数扩展
    bit P;  // 当前未实现 
    bit O;  // 保留
    bit N;  // 当前未实现
    bit M;  // 当前未实现 整数乘除法扩展
    bit L;  // 保留
    bit K;  // 保留
    bit J;  // 保留
    bit I;  // RV32I/64I 基本指令集（与 E 互斥）
    bit H;  // 当前未实现 Hypervisor 扩展
    bit G;  // 保留
    bit F;  // 当前未实现 单精度浮点数扩展
    bit E;  // RV32E/64E 嵌入式指令集（与 I 互斥，请勿直接设置此值）
    bit D;  // 当前未实现 双精度浮点数扩展
    bit C;  // 当前未实现 压缩指令集扩展
    bit B;  // 当前未实现 B 扩展
    bit A;  // 当前未实现 原子指令扩展
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
    int REG_COUNT;
    int REG_LEN;

    int IALIGN;    // 指令对齐位宽,32或16
    int PC_LEN;    // 对齐省略低位后的长度，用于简化mepc,dpc等(不包括pc)，使用时请注意
    int PC_ZEROS;
  } core_cfg_t;

  function automatic core_cfg_t ComputeCoreCfg(core_raw_cfg_t raw_cfg);
    extension_cfg_t EXTENSION = raw_cfg.EXTENSION;
    int XLEN = raw_cfg.XLEN;
    core_cfg_t cfg = '{MXL: XLEN32, default: 0};
    EXTENSION.E = !EXTENSION.I;  // 标准中要求将其设为 I 标志的补码
    cfg.XLEN = XLEN;
    cfg.EXTENSION = EXTENSION;
    cfg.MXL = XLEN == 32 ? XLEN32 : XLEN64;
    cfg.REG_COUNT = EXTENSION.E ? 16 : 32;
    cfg.REG_LEN = $clog2(cfg.REG_COUNT);
    cfg.IALIGN = EXTENSION.C ? 16 : 32;
    cfg.PC_LEN = cfg.IALIGN == 32 ? XLEN - 2 : XLEN - 1;
    cfg.PC_ZEROS = XLEN - cfg.PC_LEN;
    return cfg;
  endfunction

  // 默认配置参数
  localparam core_raw_cfg_t CORE_RAW_DEFAULT_CFG = '{EXTENSION: '{I: 1'b1, default: 1'b0}, XLEN: 32};
  localparam core_cfg_t CORE_DEFAULT_CFG = ComputeCoreCfg(CORE_RAW_DEFAULT_CFG);


  function automatic logic [63:0] PadPC(logic [63:0] pc, int ZEROS);
    return pc << ZEROS;
  endfunction

endpackage
