package SocConfig;
  import XT_HBUS_Pkg::HB_ID_WIDTH;

  //----------内存RAM----------//
  // 实际上由IP核决定，这里不一定对
  localparam int INST_RAM_DEPTH = 1024;
  localparam int DATA_RAM_DEPTH = 1024;




  // 内核
  localparam int HB_MASTER_NUM = 1;
  // 指令RAM,数据RAM,系统外设,WISHBONE,XT_LB
  localparam int HB_DEVICE_NUM = 5;
  // 设备基准ID分配，分别是上面那些设备
  localparam bit [HB_ID_WIDTH-1:0] DEVICE_BASE_ID[HB_DEVICE_NUM-1] = {3'd1, 3'd2, 3'd3, 3'd4};
  // IO设备索引分配
  localparam int IDX_XT_LB = 4, IDX_WISHBONE = 3, IDX_SYS_P = 2, IDX_DATA_RAM = 1, IDX_INST_RAM = 0;
  // HB从设备ID分配
  // DEBUG,外部中断控制器,机器计时器,UART
  //   localparam int HB_SLAVE_NUM = 4;
  //   localparam int HB_IDX_UART = 3, HB_IDX_SYSTEMTIMER = 2, HB_IDX_EINT_CTRL = 1, HB_IDX_BOOTLOADER = 0;


endpackage

