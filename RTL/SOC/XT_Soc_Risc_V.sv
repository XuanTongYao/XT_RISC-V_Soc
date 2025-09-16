`include "./../Defines/AddressDefines.sv"

// 新增GPIO复用功能后，rgb移入GPIO
module XT_Soc_Risc_V
  import XT_BUS::*;
#(
    parameter int GPIO_NUM = 32,
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
    inout                       spi_mosi
);


  //----------时钟树----------//
  wire clk_inner_osc;
  OSCH #("2.15") osc_int (  //2.15MHz for XO2
      .STDBY(1'b0),
      .OSC(clk_inner_osc),
      .SEDSTDBY()
  );

  wire pll_lock;
  wire pll_rst;
  ClockMonitor #(
      .MAX_LOCK_PERIOD((2_150_000 / 1_000) * 40),
      .POWERUP_PERIOD (0)
  ) u_ClockMonitor (
      .*,
      .independent_clk(clk_inner_osc),
      .extern_pll_rst (rst_sw)
  );

  wire clk;
  wire systemtimer_clk;  // 1MHz
  wire sampling_clk;  // 153_846，生成19200波特率误差0.16%
  wire lb_clk;  // 100K
  wire rst_sync = ~pll_lock;
  SystemPLL u_SystmePLL (
      .CLKI(clk_osc),
      .CLKOP(clk),
      .CLKOS(systemtimer_clk),
      .CLKOS2(sampling_clk),
      .CLKOS3(lb_clk),
      .RST(pll_rst),
      .LOCK(pll_lock)
  );


  //----------XT_HB高速总线互联定义----------//
  // 内核
  localparam int HB_MASTER_NUM = 1;
  // 指令RAM,数据RAM,XT_HB,WISHBONE,XT_LB
  localparam int HB_DEVICE_NUM = 5;
  // DEBUG,外部中断控制器,机器计时器,UART
  localparam int HB_SLAVE_NUM = 4;
  // 设备基地址
  localparam int DEVICE_BASE_ADDR[HB_DEVICE_NUM-1] = {
    `DATA_RAM_BASE, `DOMAIN_XT_HB_BASE, `DOMAIN_WISHBONE_BASE, `DOMAIN_XT_LB_BASE
  };
  // IO设备ID分配
  localparam int ID_XT_LB = 4, ID_WISHBONE = 3, ID_XT_HB = 2, ID_DATA_RAM = 1, ID_INST_RAM = 0;
  // HB从设备ID分配
  localparam int HB_ID_UART = 3, HB_ID_SYSTEMTIMER = 2, HB_ID_EINT_CTRL = 1, HB_ID_BOOTLOADER = 0;


  // 高速总线
  wire hb_master_in_t master_in[HB_MASTER_NUM];  // 主机输入
  wire [31:0] device_data_in[HB_DEVICE_NUM];
  wire [HB_DEVICE_NUM-1:0] read_finish;
  wire [HB_DEVICE_NUM-1:0] write_finish;
  // 总线扇出
  wire hb_clk = clk;
  wire hb_slave_t xt_hb;
  wire [31:0] hb_rdata;
  wire sel_t device_sel[HB_DEVICE_NUM];
  wire [HB_MASTER_NUM-1:0] read_grant, write_grant, stall_req;
  // 总线IO设备
  wire [31:0] hb_data_in[HB_SLAVE_NUM];
  wire sel_t hb_sel[HB_SLAVE_NUM];


  // 直连RAM/ROM(指令读取)
  wire [31:0] instruction_addr;
  wire [31:0] instruction;
  wire core_stall_n;
  wire [31:0] instruction_addr_id_ex_debug;

  // 与高速总线相连
  wire [31:0] access_ram_raddr, access_ram_waddr;
  assign master_in[0].raddr = access_ram_raddr[HB_ADDR_WIDTH-1:0];
  assign master_in[0].waddr = access_ram_waddr[HB_ADDR_WIDTH-1:0];
  // 中断相关
  wire mextern_int;
  wire msoftware_int = 0;  // 单核，为0即可
  wire mtimer_int;
  wire [30:0] mextern_int_id;
  RISC_V_Core #(
      .INST_FETCH_REG(1)
  ) u_RISC_V_Core (
      .*,
      // 与高速总线相连
      .access_ram_read       (master_in[0].read),
      .access_ram_write      (master_in[0].write),
      .access_ram_write_width(master_in[0].write_width),
      .access_ram_rdata      (hb_rdata),
      .access_ram_wdata      (master_in[0].wdata),
      .stall_req             (stall_req[0])
  );


  // 高速总线
  XT_HB #(
      .MASTER_NUM(HB_MASTER_NUM),  // 总线上主设备的数量
      .DEVICE_NUM(HB_DEVICE_NUM),  // 总线上IO设备的数量
      .DEVICE_BASE_ADDR(DEVICE_BASE_ADDR)
  ) u_XT_HB (
      .*,
      .bus(xt_hb),
      .device_sel(device_sel),
      .stall_req(stall_req)
  );


  // 高速总线本地地址域
  XT_HB_Domain #(
      .SLAVE_NUM(HB_SLAVE_NUM)
  ) u_XT_HB_Domain (
      .*,
      .sel(device_sel[ID_XT_HB]),
      .read_finish(read_finish[ID_XT_HB]),
      .write_finish(write_finish[ID_XT_HB]),
      .rdata(device_data_in[ID_XT_HB])
  );


  // 自举启动和调试控制
  // 已经可以自举启动和下载程序
  wire [31:0] bootloader_instruction;
  wire [31:0] user_instruction;
  HarvardBootloader u_HarvardBootloader (
      .*,
      .sel(hb_sel[HB_ID_BOOTLOADER]),
      .rdata(hb_data_in[HB_ID_BOOTLOADER]),
      .download_mode(download_mode)
  );

  // Bootloader和Debug固化程序
  localparam int ROM_DEPTH = 256;
  localparam int ROM_ADDR_WIDTH = $clog2(ROM_DEPTH * 4);
  rom_boot u_ROM (
      .Address(instruction_addr[ROM_ADDR_WIDTH-1:2]),
      .OutClock(clk),
      .OutClockEn(core_stall_n),
      .Reset(1'b0),
      .Q(bootloader_instruction)
  );



  // 系统RAM
  HarvardSystemRAM_BUS #(
      // 字深度(最大为2^30对应4GB字节)
      .DATA_RAM_DEPTH(`RAM_DEPTH),
      .INST_RAM_DEPTH(`INST_RAM_DEPTH)
  ) u_HarvardSystemRAM (
      .*,
      .inst_fetch_clk_en    (core_stall_n),
      // 数据RAM
      .ram_data_sel         (device_sel[ID_DATA_RAM]),
      .ram_data_rdata       (device_data_in[ID_DATA_RAM]),
      .ram_data_read_finish (read_finish[ID_DATA_RAM]),
      .ram_data_write_finish(write_finish[ID_DATA_RAM]),
      // 指令RAM
      .ram_inst_sel         (device_sel[ID_INST_RAM]),
      .inst_fetch_addr      (instruction_addr),
      .inst_fetch           (user_instruction),
      .ram_inst_read_finish (read_finish[ID_INST_RAM]),
      .ram_inst_write_finish(write_finish[ID_INST_RAM])
  );


  // 外部中断控制器
  localparam int EXTERNAL_INT_NUM = 13;
  wire [EXTERNAL_INT_NUM-1:0] irq_source;
  assign irq_source[7:1] = 7'b0;
  External_INT_Ctrl #(
      .INT_NUM(EXTERNAL_INT_NUM)
  ) u_External_INT_Ctrl (
      .*,
      .sel  (hb_sel[HB_ID_EINT_CTRL]),
      .rdata(hb_data_in[HB_ID_EINT_CTRL])
  );


  // mtime和mtimecmp
  SystemTimer u_SystemTimer (
      .*,
      .sel  (hb_sel[HB_ID_SYSTEMTIMER]),
      .rdata(hb_data_in[HB_ID_SYSTEMTIMER])
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
      .wb_ack_i    (wb_ack_o),
      .wb_dat_i    (wb_dat_o),
      .wb_dat_o    (wb_dat_i),
      .wb_cyc_o    (wb_cyc_i),
      .wb_stb_o    (wb_stb_i),
      .wb_we_o     (wb_we_i),
      .wb_adr_o    (wb_adr_i),
      // 与XT_HB总线
      .sel         (device_sel[ID_WISHBONE]),
      .read_finish (read_finish[ID_WISHBONE]),
      .write_finish(write_finish[ID_WISHBONE]),
      .rdata       (device_data_in[ID_WISHBONE])
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
  localparam int LB_SLAVE_NUM = 4;
  wire [31:0] lb_data_in[LB_SLAVE_NUM];
  wire lb_slave_t xt_lb;
  XT_LB #(
      .SLAVE_NUM(LB_SLAVE_NUM)
  ) u_XT_LB (
      .*,
      .sel         (device_sel[ID_XT_LB]),
      .read_finish (read_finish[ID_XT_LB]),
      .write_finish(write_finish[ID_XT_LB]),
      .rdata       (device_data_in[ID_XT_LB]),
      // 低速总线部分
      .bus         (xt_lb)
  );

  SW_KEY_LBUS u_SW_KEY_LBUS (
      .*,
      .rdata (lb_data_in[0][15:0]),
      .sw_raw({sw_raw, download_mode})
  );


  //   GPIO_LBUS #(
  //       .NUM(GPIO_NUM)
  //   ) u_GPIO_LBUS (
  //       .*,
  //       .rdata(lb_data_in[1][GPIO_NUM-1:0]),
  //       .gpio (gpio)
  //   );

  LED_LBUS #(
      .LED_NUM(8)
  ) u_LED_LBUS (
      .*,
      .rdata(lb_data_in[2][7:0]),
      .led  (led)
  );

  LEDSD_Direct_LBUS u_LEDSD_Direct_BUS (
      .*,
      .rdata(lb_data_in[3][7:0]),
      .ledsd(ledsd)
  );

  localparam int AF_FUNCT_IN_NUM = 2;
  wire funct_in[AF_FUNCT_IN_NUM];
  assign tc_rst = funct_in[0];
  assign tc_ic  = funct_in[1];
  AF_GPIO_LBUS #(
      .NUM           (GPIO_NUM),
      .FUNCT_IN_NUM  (AF_FUNCT_IN_NUM),
      .FUNCT_IN_MASK ({32'h0000_00FF, 32'h0000_00FF}),
      .FUNCT_OUT_NUM (2),
      .FUNCT_OUT_MASK({32'h1FE0_0000, 32'h1FE0_0000}),
      .BASE_ADDR     (8'd24)
  ) u_AF_GPIO_LBUS (
      .*,
      .gpio_clk (clk),
      .rdata    (lb_data_in[1]),
      .funct_in (funct_in),
      .funct_out({tc_oc, af_spi_csn}),
      .gpio     (gpio)
  );


  //----------高速总线外设----------//
  UART_BUS #(
      // 超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
      // 必须为偶数，最小为8
      .OVER_SAMPLING(8)
  ) u_UART (
      .*,
      .sel         (hb_sel[HB_ID_UART]),
      .rdata       (hb_data_in[HB_ID_UART]),
      // 超采样时钟(必须比总线时钟低)
      .sampling_clk(sampling_clk),
      .rx_irq      (irq_source[0])
  );


endmodule

