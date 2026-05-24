package SocConfig;
  import CoreConfig::*;

  //----------内核配置----------//
  localparam core_raw_cfg_t CORE_RAW_CFG = '{EXTENSION: '{E: 0, default: 0}, XLEN: 32};
  localparam core_cfg_t CORE_CFG = ComputeCoreCfg(CORE_RAW_CFG);


  //----------主存----------//
  // 实际上由IP核决定，这里不一定对
  localparam int INST_RAM_DEPTH = 1024;
  localparam int DATA_RAM_DEPTH = 1024;



  // XT_HB的地址，高位是识别符，低位是偏移量，基地址在识别符上对齐
  // 只使用一个识别符的设备，地址偏移量可以直接作为访问地址使用
  // 使用多个识别符的设备，用完整地址减去基地址作为访问地址使用
  localparam int HB_ADDR_WIDTH = 15;  // 总线可寻址位宽(必须比RAM位宽大)
  localparam int HB_ID_WIDTH = 3;  // 识别符占用宽度
  localparam int HB_OFFSET_WIDTH = HB_ADDR_WIDTH - HB_ID_WIDTH;  // 偏移量占用宽度

  // 高速总线主设备索引分配
  typedef enum int {
    M_IDX_CORE = 0  // 内核
  } xt_hb_master_idx_t;
  xt_hb_master_idx_t _xt_hb_master_idx_t = _xt_hb_master_idx_t.first;
  localparam int HB_MASTER_COUNT = _xt_hb_master_idx_t.num;

  // 高速总线IO设备索引分配
  typedef enum int {
    IDX_INST_RAM = 0,  // 指令RAM
    IDX_DATA_RAM,      // 数据RAM
    IDX_HB32,          // 32bit对齐总线适配器
    IDX_WISHBONE,      // WISHBONE
    IDX_XT_LB          // XT_LB
  } xt_hb_idx_t;
  xt_hb_idx_t _xt_hb_idx_t = _xt_hb_idx_t.first;
  localparam int HB_DEVICE_COUNT = _xt_hb_idx_t.num;
  // 设备基准ID分配，分别是上面那些设备
  localparam bit [HB_ID_WIDTH-1:0] DEVICE_BASE_ID[HB_DEVICE_COUNT-1] = '{3'd1, 3'd2, 3'd3, 3'd4};



  // HB32从设备ID(也是索引)分配
  typedef enum int {
    IDX_BOOTLOADER   = 0,
    IDX_EINT_CTRL,
    IDX_SYSTEM_TIMER,
    IDX_UART,
    IDX_SOFTWARE_INT
  } hb32_idx_t;
  hb32_idx_t _hb32_idx_t = _hb32_idx_t.first;
  localparam int HB32_DEVICE_COUNT = _hb32_idx_t.num;
  localparam int HB32_ADDR_WIDTH = 5;
  localparam int HB32_ID_WIDTH = 3;
  localparam int HB32_OFFSET_WIDTH = HB32_ADDR_WIDTH - HB32_ID_WIDTH;


endpackage

