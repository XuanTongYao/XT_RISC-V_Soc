// 带功能复用设计的GPIO模块
// GPIO输入输出都有寄存器缓冲,缓冲时钟独立于lb_clk
module AF_GPIO_LBUS
  import XT_BUS::*;
#(
    parameter int NUM = 10,
    // 输入/输出功能数量(最多6个)
    parameter int FUNCT_IN_NUM = 1,
    // 功能复用是功能从8个IO选择1个，掩码确定8个IO对应gpio哪几个
    // 非压缩数组,左索引是0 和funct_in对应
    parameter bit [31:0] FUNCT_IN_MASK[FUNCT_IN_NUM],
    parameter int FUNCT_OUT_NUM = 1,
    parameter bit [31:0] FUNCT_OUT_MASK[FUNCT_OUT_NUM],
    parameter bit [7:0] BASE_ADDR = 8'd4  //基地址
) (
    input gpio_clk,
    input lb_clk,
    input lb_slave_t xt_lb,
    output logic [31:0] rdata,

    // funct_in、funct_out非压缩数组,左索引是0
    output logic funct_in[FUNCT_IN_NUM],
    input funct_out[FUNCT_OUT_NUM],
    inout [NUM-1:0] gpio
);
  localparam bit [7:0] BASE_ADDR_DIR = BASE_ADDR;
  localparam bit [7:0] BASE_ADDR_DATA = BASE_ADDR + 8'd4;
  localparam bit [7:0] BASE_ADDR_AF_IN = BASE_ADDR_DATA + 8'd4;
  localparam bit [7:0] BASE_ADDR_AF_OUT = BASE_ADDR_AF_IN + 8'd4;


  // 方向寄存器0:输入  1:输出
  logic [NUM-1:0] gpio_dir_reg = 0;

  // 数据寄存器
  logic [NUM-1:0] gpio_out_data_reg;

  // GPIO控制
  logic [NUM-1:0] gpio_out_af_en;
  logic [NUM-1:0] gpio_out_af_val;
  logic [NUM-1:0] gpio_in_reg;
  logic [NUM-1:0] gpio_out_reg;
  always_ff @(posedge gpio_clk) begin
    gpio_in_reg <= gpio;
    for (int i = 0; i < NUM; ++i) begin
      if (gpio_out_af_en[i]) begin
        gpio_out_reg[i] <= gpio_out_af_val[i];
      end else begin
        gpio_out_reg[i] <= gpio_out_data_reg[i];
      end
    end
  end
  generate
    for (genvar i = 0; i < NUM; ++i) begin : gen_assign_gpio
      assign gpio[i] = gpio_dir_reg[i] ? gpio_out_reg[i] : 1'bz;
    end
  endgenerate


  // 功能复用寄存器，从input开始
  typedef struct packed {
    logic enable;
    logic [2:0] gpio_sel;  // 8选1
  } funct_af_t;

  funct_af_t [FUNCT_IN_NUM-1:0] funct_in_af_reg;
  generate
    for (genvar i_af = 0; i_af < FUNCT_IN_NUM; ++i_af) begin : gen_af_funct_in
      // 32映射8
      logic [7:0] remap_gpio;
      always_comb begin
        int re;
        re = 0;
        remap_gpio = 0;
        for (int i = 0; i < 32 && re < 8; ++i) begin
          if (FUNCT_IN_MASK[i_af][i]) begin
            remap_gpio[re] = gpio[i];
            re++;
          end
        end
      end
      // 复用
      funct_af_t af_reg;
      assign af_reg = funct_in_af_reg[i_af];
      assign funct_in[i_af] = af_reg.enable ? remap_gpio[af_reg.gpio_sel] : 1'b0;
    end
  endgenerate

  funct_af_t [FUNCT_OUT_NUM-1:0] funct_out_af_reg;
  always_comb begin
    int re;
    int gpio_index;
    int remap_list [8];  // 真实GPIO索引
    int matched;
    for (int i = 0; i < NUM; ++i) begin
      matched = 0;
      gpio_out_af_en[i] = 0;
      gpio_out_af_val[i] = 0;
      for (int o_af = 0; o_af < FUNCT_OUT_NUM; ++o_af) begin
        re = 0;
        gpio_index = 0;
        remap_list = '{default: 33};
        for (int j = 0; j < 32 && re < 8; ++j) begin
          if (FUNCT_OUT_MASK[o_af][j]) begin
            remap_list[re] = j;
            re++;
          end
        end

        gpio_index = remap_list[funct_out_af_reg[o_af].gpio_sel];
        if (gpio_index == 33 || matched == 1) begin
          continue;
        end
        if (funct_out_af_reg[o_af].enable && gpio_index == i) begin
          matched = 1;
          gpio_out_af_val[i] = funct_out[o_af];
          gpio_out_af_en[i] = 1;
          continue;
        end
      end
    end
  end


  // 写寄存器
  always_ff @(posedge lb_clk) begin
    if (MatchWLB(xt_lb, BASE_ADDR_DIR)) begin
      gpio_dir_reg <= xt_lb.wdata;
    end
    if (MatchWLB(xt_lb, BASE_ADDR_DATA)) begin
      gpio_out_data_reg <= xt_lb.wdata;
    end
    if (MatchWLB(xt_lb, BASE_ADDR_AF_IN)) begin
      funct_in_af_reg <= xt_lb.wdata;
    end
    if (MatchWLB(xt_lb, BASE_ADDR_AF_OUT)) begin
      funct_out_af_reg <= xt_lb.wdata;
    end
  end

  // 读寄存器
  always_comb begin
    if (MatchRLB(xt_lb, BASE_ADDR_DIR)) begin
      rdata = gpio_dir_reg;
    end else if (MatchRLB(xt_lb, BASE_ADDR_DATA)) begin
      rdata = gpio_in_reg;
    end else if (MatchRLB(xt_lb, BASE_ADDR_AF_IN)) begin
      rdata = funct_in_af_reg;
    end else if (MatchRLB(xt_lb, BASE_ADDR_AF_OUT)) begin
      rdata = funct_out_af_reg;
    end else begin
      rdata = 0;
    end
  end

endmodule



