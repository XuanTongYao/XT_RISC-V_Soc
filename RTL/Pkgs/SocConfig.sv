package SocConfig;
  import CoreConfig::*;
  import AfGpio_Pkg::*;

  //----------内核配置----------//
  localparam core_raw_cfg_t CORE_RAW_CFG = '{EXTENSION: '{E: 0, default: 0}, XLEN: 32};
  localparam core_cfg_t CORE_CFG = ComputeCoreCfg(CORE_RAW_CFG);


  localparam int RAM_DEPTH = 2048;


  //----------高速总线----------//
  // XT_HB的地址，高位是识别符，低位是偏移量，基地址在识别符上对齐
  // 只使用一个识别符的设备，地址偏移量可以直接作为访问地址使用
  // 使用多个识别符的设备，用完整地址减去基地址作为访问地址使用
  localparam int HB_ADDR_WIDTH = 15;  // 总线可寻址位宽(必须比RAM位宽大)
  localparam int HB_ID_WIDTH = 3;  // 识别符占用宽度
  localparam int HB_OFFSET_WIDTH = HB_ADDR_WIDTH - HB_ID_WIDTH;  // 偏移量占用宽度

  // 高速总线主设备索引分配
  typedef enum int {
    M_IDX_CORE = 0,  // 内核
    M_IDX_DM         // 调试模块
  } xt_hb_master_idx_t;
  xt_hb_master_idx_t _xt_hb_master_idx_t = _xt_hb_master_idx_t.first;
  localparam int HB_MASTER_COUNT = _xt_hb_master_idx_t.num;

  // 高速总线IO设备索引分配
  typedef enum int {
    IDX_RAM      = 0,  // 主存RAM
    IDX_HB32,          // 32bit对齐总线适配器
    IDX_WISHBONE,      // WISHBONE
    IDX_XT_LB          // XT_LB
  } xt_hb_idx_t;
  xt_hb_idx_t _xt_hb_idx_t = _xt_hb_idx_t.first;
  localparam int HB_DEVICE_COUNT = _xt_hb_idx_t.num;
  // 设备基准ID分配，分别是上面那些设备
  localparam bit [HB_ID_WIDTH-1:0] DEVICE_BASE_ID[HB_DEVICE_COUNT-1] = '{3'd2, 3'd3, 3'd4};



  // HB32从设备ID(也是索引)分配
  typedef enum int {
    IDX_BOOTLOADER   = 0,
    IDX_EINT_CTRL,
    IDX_SYSTEM_TIMER,
    IDX_UART,
    IDX_SOFTWARE_INT,
    IDX_GPIO
  } hb32_idx_t;
  hb32_idx_t _hb32_idx_t = _hb32_idx_t.first;
  localparam int HB32_DEVICE_COUNT = _hb32_idx_t.num;
  localparam int HB32_ADDR_WIDTH = 6;
  localparam int HB32_ID_WIDTH = 3;
  localparam int HB32_OFFSET_WIDTH = HB32_ADDR_WIDTH - HB32_ID_WIDTH;


  //----------GPIO----------//
  localparam int GPIO_COUNT = 30;

  // 复用功能ID
  typedef enum int {
    TIMER_INPUT = 0,
    TIMER_RST,
    SPI_SCSN
  } af_in_id_t;
  af_in_id_t _af_in_id_t = _af_in_id_t.first;
  localparam int AF_FUNCT_IN_COUNT = _af_in_id_t.num;

  typedef enum int {
    TIMER_OUTPUT = 0,
    SPI_CSN1,
    SPI_CSN2,
    SPI_CSN3,
    SPI_CSN4,
    SPI_CSN5,
    SPI_CSN6,
    SPI_CSN7
  } af_out_id_t;
  af_out_id_t _af_out_id_t = _af_out_id_t.first;
  localparam int AF_FUNCT_OUT_COUNT = _af_out_id_t.num;

  localparam gpio_af_cfg_t IN_OUT_0_1_2_3 = '{
      in_valid: 1'b1,
      out_valid: 1'b1,
      in_sel: '{TIMER_INPUT, TIMER_RST, SPI_SCSN, -1},
      out_sel: '{TIMER_OUTPUT, SPI_CSN1, SPI_CSN2, SPI_CSN3}
  };

  localparam gpio_af_cfg_t OUT_0 = '{
      in_valid: 1'b0,
      out_valid: 1'b1,
      in_sel: '{default: -1},
      out_sel: '{default: TIMER_OUTPUT}
  };

  localparam gpio_af_cfg_t OUT_0_1_2_3 = '{
      in_valid: 1'b0,
      out_valid: 1'b1,
      in_sel: '{default: -1},
      out_sel: '{TIMER_OUTPUT, SPI_CSN1, SPI_CSN2, SPI_CSN3}
  };

  localparam gpio_af_cfg_t OUT_4_5_6_7 = '{
      in_valid: 1'b0,
      out_valid: 1'b1,
      in_sel: '{default: -1},
      out_sel: '{SPI_CSN4, SPI_CSN5, SPI_CSN6, SPI_CSN7}
  };


  localparam gpio_af_cfg_t AF_CFGS[GPIO_COUNT] = '{
      0: IN_OUT_0_1_2_3,  // GPIO复用计时器与SPI片选
      1: IN_OUT_0_1_2_3,
      2: IN_OUT_0_1_2_3,
      3: IN_OUT_0_1_2_3,
      4: OUT_0_1_2_3,  // GPIO复用SPI片选
      5: OUT_0_1_2_3,
      6: OUT_0_1_2_3,
      7: OUT_0_1_2_3,
      8: OUT_4_5_6_7,  // GPIO复用SPI片选
      9: OUT_4_5_6_7,
      10: OUT_4_5_6_7,
      11: OUT_4_5_6_7,
      24: OUT_0,  // RGB灯珠
      25: OUT_0,
      26: OUT_0,
      27: OUT_0,
      28: OUT_0,
      29: OUT_0,
      default: NONE_AF_CFG
  };

endpackage

