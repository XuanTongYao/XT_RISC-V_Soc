`include "./../Defines/AddressDefines.sv"

module XT_Soc_Risc_V
  import XT_BUS::*;
#(
    parameter int GPIO_NUM = 30
) (
    input                       clk_osc,
    input                       rst_sw,
    input                       download_mode,
    output logic [         2:0] rgb,
    output logic [         2:0] rgb2,
    inout        [GPIO_NUM-1:0] gpio,
    input        [         3:0] key_raw,
    input        [         1:0] sw_raw,
    output logic [         7:0] led,
    output logic [         8:0] ledsd        [2],
    input                       uart_rx,
    output logic                uart_tx,
    inout                       i2c1_scl,
    inout                       i2c1_sda
);
  assign rgb2[1] = rgb2[0];
  assign rgb2[2] = rgb2[0];
  assign rgb = {3{rgb2[0]}};


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
      .POWERUP_PERIOD (2_150_000)
  ) u_ClockMonitor (
      .*,
      .independent_clk(clk_inner_osc),
      .extern_pll_rst (rst_sw)
  );

  wire clk;
  wire systemtimer_clk;  // 1MHz
  wire sampling_clk;  // 153_600，生成19200波特率误差0.16%
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




  //----------RAM与内核定义----------//
  localparam int INST_RAM_DEPTH = 512;
  localparam int INST_RAM_ADDR_WIDTH = $clog2(INST_RAM_DEPTH * 4);
  localparam int RAM_DEPTH = 512;
  localparam int RAM_ADDR_WIDTH = $clog2(RAM_DEPTH * 4);
  `define INST_RAM_LEN (INST_RAM_DEPTH*4)
  `define DATA_RAM_LEN (RAM_DEPTH*4)
  `define INST_RAM_BASE 0
  `define DATA_RAM_BASE (`INST_RAM_BASE+`INST_RAM_LEN)
  localparam int STALL_REQ_NUM = 1;


  //----------XT_HB高速总线互联定义----------//
  localparam int HB_MASTER_NUM = 1;  // 内核
  // 指令RAM,数据RAM,DEBUG,外部中断控制器,系统计时器,UART,WISHBONE,XT_LB
  localparam int HB_SLAVE_NUM = 8;
  // 地址映射分割
  localparam int ADDR_SPLIT[HB_SLAVE_NUM-1] = {
    `DATA_RAM_BASE, `DEBUG_BASE, `EINT_CTRL_BASE, `SYSTEM_TIMER_BASE, `UART_BASE, `WISHBONE_BASE, `XT_LB_BASE
  };
  // 从设备ID分配
  localparam int ID_XT_LB = 7, ID_WISHBONE = 6, ID_UART = 5, ID_SYSTEMTIMER = 4, ID_EINT_CTRL = 3, ID_BOOTLOADER = 2,
      ID_RAM = 1, ID_INST_RAM = 0;

  // 高速总线
  // 主机输入
  wire [HB_MASTER_NUM-1:0] master_req_in;
  wire hb_master_in_t master_in[HB_MASTER_NUM];
  wire [31:0] slave_data_in[HB_SLAVE_NUM];
  wire [HB_SLAVE_NUM-1:0] wait_finish;
  assign wait_finish[ID_UART:0] = {ID_WISHBONE{1'b1}};
  // 总线扇出
  wire [HB_MASTER_NUM-1:0] master_accept;
  wire hb_clk = clk;
  wire hb_slave_t xt_hb;
  wire [31:0] hb_rdata;
  wire sel_t hb_sel[HB_SLAVE_NUM];


  // 直连RAM/ROM(指令读取)
  wire [31:0] instruction_addr;
  wire [31:0] instruction;
  wire [STALL_REQ_NUM-1:0] stall_req;
  wire core_stall_n;
  wire [31:0] instruction_addr_id_ex_debug;

  // 与高速总线相连
  wire [31:0] access_ram_raddr, access_ram_waddr;
  assign master_in[0].raddr = access_ram_raddr[HB_ADDR_WIDTH-1:0];
  assign master_in[0].waddr = access_ram_waddr[HB_ADDR_WIDTH-1:0];
  assign master_req_in[0]   = master_in[0].read || master_in[0].write;
  // 中断相关
  wire mextern_int;
  wire msoftware_int = 0;  // 单核，为0即可
  wire mtimer_int;
  wire [30:0] mextern_int_id;
  RISC_V_Core #(
      .INST_FETCH_REG(1),
      .STALL_REQ_NUM (STALL_REQ_NUM)
  ) u_RISC_V_Core (
      .*,
      // 与高速总线相连
      .access_ram_read       (master_in[0].read),
      .access_ram_write      (master_in[0].write),
      .access_ram_write_width(master_in[0].write_width),
      .access_ram_rdata      (hb_rdata),
      .access_ram_wdata      (master_in[0].wdata)
  );


  // 高速总线
  XT_HB #(
      .MASTER_NUM(HB_MASTER_NUM),  // 总线上主设备的数量
      .SLAVE_NUM (HB_SLAVE_NUM),   // 总线上从设备的数量
      .ADDR_SPLIT(ADDR_SPLIT)
  ) u_XT_HB (
      .*,
      .master_rdata(hb_rdata),
      .bus(xt_hb),
      .slave_sel(hb_sel),
      .stall_req(stall_req[0])
  );


  // 自举启动和调试控制
  // 已经可以自举启动和下载程序
  wire [31:0] bootloader_instruction;
  wire [31:0] user_instruction;
  HarvardBootloader u_HarvardBootloader (
      .*,
      // 总线接口
      .sel          (hb_sel[ID_BOOTLOADER]),
      .rdata        (slave_data_in[ID_BOOTLOADER]),
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
  wire clk_en = core_stall_n;
  HarvardSystemRAM_BUS #(
      // 字深度(最大为2^30对应4GB字节)
      .DATA_RAM_DEPTH(RAM_DEPTH),
      .INST_RAM_DEPTH(INST_RAM_DEPTH)
  ) u_HarvardSystemRAM (
      .*,
      .clk_en                (clk_en),
      // 与高速总线
      // 数据RAM
      .ram_sel               (hb_sel[ID_RAM]),
      .ram_r_data            (slave_data_in[ID_RAM]),
      // 指令RAM
      .ram_inst              (hb_sel[ID_INST_RAM]),
      .ram_instruction_r_addr(instruction_addr[INST_RAM_ADDR_WIDTH-1:0]),
      .ram_instruction_r_data(user_instruction)
  );


  // 外部中断控制器
  localparam int EXTERNAL_INT_NUM = 1;
  wire [EXTERNAL_INT_NUM-1:0] irq_source;
  External_INT_Ctrl #(
      .INT_NUM(EXTERNAL_INT_NUM)
  ) u_External_INT_Ctrl (
      .*,
      .sel  (hb_sel[ID_EINT_CTRL]),
      .rdata(slave_data_in[ID_EINT_CTRL])
  );


  // 系统计时器
  SystemTimer u_SystemTimer (
      // 计时时钟一定比高速总线时钟慢
      .*,
      // 与高速总线
      .sel  (hb_sel[ID_SYSTEMTIMER]),
      .rdata(slave_data_in[ID_SYSTEMTIMER])
  );



  //----------WISHBONE总线外设----------//
  wire wb_clk_i;
  wire wb_rst_i;
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
      .wb_ack_i   (wb_ack_o),
      .wb_dat_i   (wb_dat_o),
      .wb_dat_o   (wb_dat_i),
      .wb_cyc_o   (wb_cyc_i),
      .wb_stb_o   (wb_stb_i),
      .wb_we_o    (wb_we_i),
      .wb_adr_o   (wb_adr_i),
      // 与XT_HB总线
      .sel        (hb_sel[ID_WISHBONE]),
      .wait_finish(wait_finish[ID_WISHBONE]),
      .rdata      (slave_data_in[ID_WISHBONE])
  );

  wire spi_scsn = 1;
  wire ufm_sn = 1;
  wire tc_rstn = 1;
  wire tc_ic = 0;
  wire wbc_ufm_irq;
  wire i2c1_irqo;
  wire tc_int;
  efb u_efb (
      .*,
      .tc_clki(clk_osc),
      .wbc_ufm_irq(),
      .tc_int(),
      .tc_oc(rgb2[0])
  );


  //----------低速总线及其外设----------//
  localparam int LB_SLAVE_NUM = 4;
  wire [31:0] lb_data_in[LB_SLAVE_NUM];
  wire lb_slave_t xt_lb;
  XT_LB #(
      .SLAVE_NUM(LB_SLAVE_NUM)
  ) u_XT_LB (
      // 与高速总线桥接
      .*,
      .sel        (hb_sel[ID_XT_LB]),
      .wait_finish(wait_finish[ID_XT_LB]),
      .rdata      (slave_data_in[ID_XT_LB]),
      // 低速总线部分
      .bus        (xt_lb)
  );

  SW_KEY_LBUS u_SW_KEY_LBUS (
      .*,
      .rdata (lb_data_in[0][15:0]),
      .sw_raw({sw_raw, download_mode})
  );

  GPIO_LBUS #(
      .NUM(GPIO_NUM)
  ) u_GPIO_LBUS (
      .*,
      .rdata(lb_data_in[1][GPIO_NUM-1:0]),
      .gpio (gpio)
  );

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



  //----------外设----------//
  UART_BUS #(
      // 超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
      // 必须为偶数，最小为8
      .OVER_SAMPLING(8)
  ) u_UART (
      .*,
      .sel         (hb_sel[ID_UART]),
      .rdata       (slave_data_in[ID_UART]),
      // 超采样时钟(必须比总线时钟低)
      .sampling_clk(sampling_clk),
      .rx_irq      (irq_source[0]),
      .uart_rx     (uart_rx),
      .uart_tx     (uart_tx)
  );


endmodule

