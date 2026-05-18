package SocConfig;
  import CoreConfig::*;

  //----------内核配置----------//
  localparam core_raw_cfg_t CORE_RAW_CFG = '{EXTENSION: '{E: 0, default: 0}, XLEN: 32};
  localparam core_cfg_t CORE_CFG = ComputeCoreCfg(CORE_RAW_CFG);


  //----------内存RAM----------//
  // 实际上由IP核决定，这里不一定对
  localparam int INST_RAM_DEPTH = 1024;
  localparam int DATA_RAM_DEPTH = 1024;



  // XT_HB的地址，高位是识别符，低位是偏移量，基地址在识别符上对齐
  // 只使用一个识别符的设备，地址偏移量可以直接作为访问地址使用
  // 使用多个识别符的设备，用完整地址减去基地址作为访问地址使用
  localparam int HB_ADDR_WIDTH = 15;  // 总线可寻址位宽(必须比RAM位宽大)
  localparam int HB_ID_WIDTH = 3;  // 识别符占用宽度
  localparam int HB_OFFSET_WIDTH = HB_ADDR_WIDTH - HB_ID_WIDTH;  // 偏移量占用宽度

  // 内核
  localparam int HB_MASTER_NUM = 1;
  // 指令RAM,数据RAM,系统外设,WISHBONE,XT_LB
  localparam int HB_DEVICE_NUM = 5;
  // 设备基准ID分配，分别是上面那些设备
  localparam bit [HB_ID_WIDTH-1:0] DEVICE_BASE_ID[HB_DEVICE_NUM-1] = '{3'd1, 3'd2, 3'd3, 3'd4};
  // IO设备索引分配
  localparam int IDX_XT_LB = 4, IDX_WISHBONE = 3, IDX_HB32 = 2, IDX_DATA_RAM = 1, IDX_INST_RAM = 0;

  // HB32从设备ID分配
  typedef enum int {
    IDX_BOOTLOADER   = 0,
    IDX_EINT_CTRL,
    IDX_SYSTEM_TIMER,
    IDX_UART,
    IDX_SOFTWARE_INT
  } hb32_idx_t;
  hb32_idx_t _hb32_idx_t = _hb32_idx_t.first;
  localparam int HB32_DEVICE_NUM = _hb32_idx_t.num;
  localparam int HB32_ADDR_WIDTH = 5;
  localparam int HB32_ID_WIDTH = 3;
  localparam bit [HB32_ID_WIDTH-1:0] HB32_DEVICE_ID[HB32_DEVICE_NUM-1] = '{'d1, 'd2, 'd3, 'd4};


endpackage

