package AfGpio_Pkg;

  // 4:1 MUX复用
  typedef struct {
    bit in_valid;
    bit out_valid;
    int in_sel[4];   // 选中功能数组中的某一位(-1表示未连接，仅限输入)
    int out_sel[4];  // 选中功能数组中的某一位
  } gpio_af_cfg_t;

  localparam gpio_af_cfg_t NONE_AF_CFG = '{
      in_valid: 1'b0,
      out_valid: 1'b0,
      in_sel: '{default: 0},
      out_sel: '{default: 0}
  };


endpackage
