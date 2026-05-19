// 新增GPIO复用功能后，rgb移入GPIO
module XT_Soc_Risc_V
  import Utils_Pkg::sel_t;
  import SocConfig::*;
#(
    parameter int GPIO_NUM = 28,
    parameter int CSN_NUM  = 2    // 专用SPI片选引脚
) (
    input                       clk_osc,
    input                       rst_sw,
    input                       download_mode,
    inout        [GPIO_NUM-1:0] gpio,
    input        [         3:0] key_raw,
    input        [         1:0] sw_raw,
    output logic [         7:0] led,
    output logic [         8:0] ledsd        [2],
    input                       uart_rx,
    output logic                uart_tx,
    inout                       i2c1_scl,
    inout                       i2c1_sda,
    inout                       i2c2_scl,
    inout                       i2c2_sda,
    input                       spi_scsn,
    output logic [ CSN_NUM-1:0] spi_csn,
    inout                       spi_clk,
    inout                       spi_miso,
    inout                       spi_mosi,

    input tck,
    input tms,
    input tdi,
    output logic tdo
);


  //----------时钟树----------//
  wire clk_inner_osc;
  OSCH #("2.15") osc_int (  //2.15MHz for XO2
      .STDBY(1'b0),
      .OSC(clk_inner_osc),
      .SEDSTDBY()
  );

  // FIXME 外部复位有点小问题
  wire pll_lock;
  wire pll_rst;
  ClockMonitor #(
      .MAX_LOCK_PERIOD((2_150_000 / 1_000) * 40),
      .POWER_ON_PERIOD(0)
  ) u_ClockMonitor (
      .*,
      .independent_clk(clk_inner_osc),
      .extern_pll_rst (rst_sw)
  );

  wire clk;
  wire systemtimer_clk;  // 1MHz
  wire sampling_clk;  // 153_846，生成19200波特率误差0.16%
  wire lb_clk;  // 100K
  SystemPLL u_SystmePLL (
      .CLKI(clk_osc),
      .CLKOP(clk),
      .CLKOS(systemtimer_clk),
      .CLKOS2(sampling_clk),
      .CLKOS3(lb_clk),
      .RST(pll_rst),
      .LOCK(pll_lock)
  );

  wire ndmreset;  // 提前声明
  wire rst_n;
  wire rst = ~rst_n;
  SyncAsyncReset u_SyncAsyncReset (
      .clk    (clk),
      .rst_i_n(pll_lock & ~ndmreset),
      .rst_o_n(rst_n)
  );

  //----------调试器----------//
  dmi_if #(.ABITS(7)) dmi ();
  wire dm_rst;
  JtagDTM #(
      .ABITS       (7),
      .IDCODE_VALUE(32'h0000_0001)
  ) u_JtagDTM (
      .*,
      .dm_clk(clk)
  );

  dm_hart_minimal_if dm_hart ();
  dm_register_if access_register ();
  DM #(
      .DATACOUNT(4'd1)
  ) u_DM (
      .*,
      .dm_clk  (clk),
      .dm_rst_n(pll_lock)
  );


  //----------XT_HB高速总线互联定义----------//
  // 在SocConfig中配置

  // 高速总线 主设备接口
  memory_direct_if hb_master[HB_MASTER_NUM] ();
  // 高速总线 IO设备接口
  xt_hbus_if #(.ADDR_WIDTH(HB_ADDR_WIDTH)) hb_if[HB_DEVICE_NUM] ();
  // 高速总线
  wire [HB_MASTER_NUM-1:0] read_grant, write_grant, stall_req;
  XT_HB #(
      .ADDR_WIDTH    (HB_ADDR_WIDTH),  // 总线上主设备的数量
      .ID_WIDTH      (HB_ID_WIDTH),    // 总线上主设备的数量
      .MASTER_NUM    (HB_MASTER_NUM),  // 总线上主设备的数量
      .DEVICE_NUM    (HB_DEVICE_NUM),  // 总线上IO设备的数量
      .DEVICE_BASE_ID(DEVICE_BASE_ID)
  ) u_XT_HB (
      .*,
      .clk(clk),
      .rst(rst),
      .master(hb_master),
      .devices(hb_if)
  );


  // 直连RAM/ROM(指令读取)
  instruction_if core_inst_if ();
  wire core_stall_n;

  // 中断相关
  wire mextern_int;
  wire msoftware_int;
  wire mtimer_int;
  wire [30:0] custom_int_code;
  int_source_if mint (.*);
  // 外部中断
  localparam int EXTERNAL_INT_NUM = 13;
  wire [EXTERNAL_INT_NUM-1:0] irq_source;
  assign irq_source[7:1] = 7'b0;

  RISC_V_Core #(
      .CFG(CORE_CFG),
      .INST_FETCH_REG(1)
  ) u_RISC_V_Core (
      .*,
      .memory   (hb_master[M_IDX_CORE]),
      .stall_req(stall_req[M_IDX_CORE]),
      .command0 (access_register)
  );

  // 提前声明，指令选择
  wire [31:0] bootloader_instruction;
  wire [31:0] user_instruction;



  // Bootloader和Debug固化程序
  localparam int ROM_DEPTH = 128;
  localparam int ROM_ADDR_WIDTH = $clog2(ROM_DEPTH * 4);
  rom_boot u_ROM (
      .Address(core_inst_if.addr[ROM_ADDR_WIDTH-1:2]),
      .OutClock(clk),
      .OutClockEn(core_inst_if.enable),
      .Reset(1'b0),
      .Q(bootloader_instruction)
  );



  // 系统RAM
  HarvardSystemRAM_BUS #(
      // 字深度(最大为2^30对应4GB字节)
      .DATA_RAM_DEPTH(DATA_RAM_DEPTH),
      .INST_RAM_DEPTH(INST_RAM_DEPTH)
  ) u_HarvardSystemRAM (
      .*,
      .inst_fetch_clk_en(core_inst_if.enable),
      // 数据RAM
      .hb               (hb_if[IDX_DATA_RAM]),
      .ram_inst         (hb_if[IDX_INST_RAM]),
      // 指令RAM
      .inst_fetch_addr  (core_inst_if.addr),
      .inst_fetch       (user_instruction)
  );


  //----------高速总线32位对齐外设----------//
  xt_hbus32_if #(.OFFSET_WIDTH(HB32_OFFSET_WIDTH)) hb32_if[HB32_DEVICE_NUM] ();
  XT_HB32_Adapter #(
      .ADDR_WIDTH(HB32_ADDR_WIDTH),
      .ID_WIDTH  (HB32_ID_WIDTH),
      .DEVICE_NUM(HB32_DEVICE_NUM)
  ) u_XT_HB32_Adapter (
      .*,
      .hb     (hb_if[IDX_HB32]),
      .devices(hb32_if)
  );

  // 从ROM自举启动和UART程序下载
  HarvardBootstrap u_HarvardBootstrap (
      .*,
      .hb(hb32_if[IDX_BOOTLOADER])
  );

  // 外部中断控制器
  External_INT_Ctrl #(
      .INT_NUM(EXTERNAL_INT_NUM)
  ) u_External_INT_Ctrl (
      .*,
      .hb(hb32_if[IDX_EINT_CTRL])
  );

  // mtime和mtimecmp
  SystemTimer u_SystemTimer (
      .*,
      .hb(hb32_if[IDX_SYSTEM_TIMER])
  );

  UART_BUS #(
      // 超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
      // 必须为偶数，最小为8
      .OVER_SAMPLING(8)
  ) u_UART (
      .*,
      .hb(hb32_if[IDX_UART]),
      .rx_irq(irq_source[0])
  );

  SoftwareINT #(
      .REG_LEN(16)
  ) u_SoftwareINT (
      .*,
      .hb(hb32_if[IDX_SOFTWARE_INT])
  );


  //----------WISHBONE总线外设----------//
  wire wb_rst_i, wb_clk_i;
  WISHBONE_SYSCON u_WISHBONE_SYSCON (
      .*,
      .wb_clk_o(wb_clk_i),
      .wb_rst_o(wb_rst_i)
  );

  wire wb_ack_o;
  wire [7:0] wb_dat_o, wb_dat_i;
  wire wb_cyc_i, wb_stb_i, wb_we_i;
  wire [7:0] wb_adr_i;
  WISHBONE_MASTER #(
      .PORT_SIZE(8)
  ) u_WISHBONE_MASTER (
      .*,
      // 与从设备
      .wb_ack_i(wb_ack_o),
      .wb_dat_i(wb_dat_o),
      .wb_dat_o(wb_dat_i),
      .wb_cyc_o(wb_cyc_i),
      .wb_stb_o(wb_stb_i),
      .wb_we_o (wb_we_i),
      .wb_adr_o(wb_adr_i),
      // 与XT_HB总线
      .hb      (hb_if[IDX_WISHBONE])
  );

  localparam int ALL_CSN_NUM = 3;
  wire ufm_sn = 1;
  wire tc_rst, tc_ic, tc_oc;  // 定时器的功能复用
  wire tc_rstn = !tc_rst;
  wire [ALL_CSN_NUM-1:0] all_spi_csn;
  assign spi_csn = all_spi_csn[CSN_NUM-1:0];
  wire [ALL_CSN_NUM-CSN_NUM-1:0] af_spi_csn = all_spi_csn[ALL_CSN_NUM-1:CSN_NUM];
  efb u_efb (
      .*,
      .tc_clki(clk_osc),
      .i2c1_irqo(irq_source[8]),
      .i2c2_irqo(irq_source[9]),
      .spi_irq(irq_source[10]),
      .tc_int(irq_source[11]),
      .wbc_ufm_irq(irq_source[12]),
      .spi_csn(all_spi_csn)
  );


  //----------低速总线及其外设----------//
  localparam int LB_ADDR_WIDTH = 8, LB_ID_WIDTH = 2, LB_DEVICE_NUM = 4;
  localparam int LB_OFFSET_WIDTH = LB_ADDR_WIDTH - LB_ID_WIDTH;
  xt_lbus_if #(.OFFSET_WIDTH(LB_OFFSET_WIDTH)) lb_if[LB_DEVICE_NUM] ();
  XT_LB #(
      .ADDR_WIDTH(LB_ADDR_WIDTH),
      .ID_WIDTH  (LB_ID_WIDTH),
      .DEVICE_NUM(LB_DEVICE_NUM)
  ) u_XT_LB (
      .*,
      .hb     (hb_if[IDX_XT_LB]),
      .devices(lb_if)
  );

  SW_KEY_LBUS u_SW_KEY_LBUS (
      .*,
      .lb(lb_if[0]),
      .sw_raw({sw_raw, download_mode})
  );

  localparam int AF_FUNCT_IN_NUM = 2;
  wire funct_in[AF_FUNCT_IN_NUM];
  assign tc_rst = funct_in[0];
  assign tc_ic  = funct_in[1];
  AF_GPIO_LBUS #(
      .NUM           (GPIO_NUM),
      .FUNCT_IN_NUM  (AF_FUNCT_IN_NUM),
      .FUNCT_IN_MASK ('{32'h0000_00FF, 32'h0000_00FF}),
      .FUNCT_OUT_NUM (2),
      .FUNCT_OUT_MASK('{32'h1FE0_0000, 32'h1FE0_0000})
  ) u_AF_GPIO_LBUS (
      .*,
      .gpio_clk (clk),
      .lb       (lb_if[1]),
      .funct_in (funct_in),
      .funct_out({tc_oc, af_spi_csn}),
      .gpio     (gpio)
  );

  LED_LBUS #(
      .LED_NUM(8)
  ) u_LED_LBUS (
      .lb (lb_if[2]),
      .led(led)
  );

  LEDSD_Direct_LBUS u_LEDSD_Direct_BUS (
      .lb(lb_if[3]),
      .ledsd(ledsd)
  );



endmodule

