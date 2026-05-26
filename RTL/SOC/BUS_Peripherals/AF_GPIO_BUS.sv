// 带功能复用设计的GPIO模块
// 每个IO端口的复用配置占用2bit，可从4个复用中选择
// 端口方向配置为不同模式时，复用的功能是不同的
// 每个IO端口总共可复用8个功能（输入4个，输出4个）
// 多个端口可配置为相同的复用输入/输出功能
// 当多个端口使用相同的输入功能时，得到的结果为它们的逻辑或
// 当多个端口使用相同的输出功能时，复用功能将在多个端口输出

// 寄存器(32bit对齐)布局参考
// 0 - DIR   方向寄存器
// 1 - DATA  数据寄存器
// 2 - AF_EN 复用功能启用寄存器
// 3 - AFL   复用配置低位(每个配置2bit，可从4个复用中选择)
// 4 - AFH   复用配置高位
module AF_GPIO_BUS
  import AfGpio_Pkg::*;
#(
    // 数量不能超过32个
    parameter int COUNT = 10,
    parameter int FUNCT_IN_COUNT = 1,
    parameter int FUNCT_OUT_COUNT = 1,
    parameter bit FUNCT_IN_RESET_VAL[FUNCT_IN_COUNT] = '{default: 1'b0},
    parameter gpio_af_cfg_t AF_CFGS[COUNT] = '{default: NONE_AF_CFG}
) (
    xt_hbus32_if.port hb,

    output logic funct_in[FUNCT_IN_COUNT],
    input funct_out[FUNCT_OUT_COUNT],
    inout [COUNT-1:0] gpio
);
  localparam bit AFH = COUNT > 16;
  localparam int AFL_COUNT = AFH ? 16 : COUNT;
  localparam int AFH_COUNT = AFH ? COUNT - 16 : 0;
  localparam int AFL_WIDTH = AFL_COUNT * 2;
  localparam int AFH_WIDTH = AFH_COUNT * 2;


  // 方向寄存器 0:输入  1:输出
  logic [COUNT-1:0] dir_reg;  // 地址0
  // 输入输出缓冲寄存器
  logic [COUNT-1:0] in_reg;  // 地址1
  logic [COUNT-1:0] out_reg;
  // 复用功能启用寄存器
  logic [COUNT-1:0] af_en_reg;  // 地址2
  // 复用配置寄存器
  logic [COUNT-1:0][1:0] af_reg;  // 地址3和地址4



  // GPIO控制
  always_ff @(posedge hb.clk) in_reg <= gpio;

  logic [COUNT-1:0] af_out, af_in;
  logic [COUNT-1:0] gpio_out;
  generate
    for (genvar i = 0; i < COUNT; ++i) begin : gen_gpio
      if (AF_CFGS[i].out_valid) begin : gen_valid_af_out
        assign gpio_out[i] = af_en_reg[i] ? af_out[i] : out_reg[i];
      end else begin : gen_invalid_af_out
        assign gpio_out[i] = out_reg[i];
      end
      assign gpio[i] = dir_reg[i] ? gpio_out[i] : 1'bz;

      // 复用映射
      if (FUNCT_IN_COUNT > 0 && AF_CFGS[i].in_valid) begin : gen_af_in
        assign af_in[i] = (af_en_reg[i] && !dir_reg[i]) ? gpio[i] : 1'b0;
      end else begin : gen_none_af_in
        assign af_in[i] = 1'b0;
      end

      if (FUNCT_OUT_COUNT > 0 && AF_CFGS[i].out_valid) begin : gen_af_out
        assign af_out[i] = funct_out[AF_CFGS[i].out_sel[af_reg[i]]];
      end else begin : gen_none_af_out
        assign af_out[i] = 1'b0;
      end
    end
  endgenerate

  always_comb begin
    for (int i = 0; i < FUNCT_IN_COUNT; ++i) begin
      funct_in[i] = FUNCT_IN_RESET_VAL[i];
      for (int io = 0; io < COUNT; ++io) begin
        if (AF_CFGS[io].in_sel[af_reg[io]] == i) funct_in[i] |= af_in[io];
      end
    end
  end



  // 总线写
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      dir_reg   <= 0;
      af_en_reg <= 0;
    end else if (hb.wen) begin
      if (hb.waddr == 'd0) begin
        dir_reg <= hb.wdata[COUNT-1:0];
      end else if (hb.waddr == 'd2) begin
        af_en_reg <= hb.wdata[COUNT-1:0];
      end
    end
  end

  always_ff @(posedge hb.clk) begin
    if (hb.wen) begin
      if (hb.waddr == 'd1) begin
        out_reg <= hb.wdata[COUNT-1:0];
      end else if (hb.waddr == 'd3) begin
        af_reg[AFL_COUNT-1:0] <= hb.wdata[AFL_WIDTH-1:0];
      end else if (hb.waddr == 'd4 && AFH) begin
        af_reg[COUNT-1:16] <= hb.wdata[AFH_WIDTH-1:0];
      end
    end
  end


  // 总线读
  always_ff @(posedge hb.clk) begin
    if (hb.ren) begin
      if (hb.raddr == 'd0) begin
        hb.rdata <= 32'(dir_reg);
      end else if (hb.raddr == 'd1) begin
        hb.rdata <= 32'(in_reg);
      end else if (hb.raddr == 'd2) begin
        hb.rdata <= 32'(af_en_reg);
      end else if (hb.raddr == 'd3) begin
        hb.rdata <= 32'(af_reg[AFL_COUNT-1:0]);
      end else begin
        hb.rdata <= AFH ? 32'(af_reg[COUNT-1:16]) : '0;
      end
    end
  end


endmodule



