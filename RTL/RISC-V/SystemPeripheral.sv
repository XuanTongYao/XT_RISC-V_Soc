// 与系统强相关的外设
// 比如内存映射CSR，外部中断控制器，自举启动和DMA等
module SystemPeripheral
  import Utils_Pkg::sel_t;
  import XT_HBUS_Pkg::*;
  import SystemPeripheral_Pkg::*;
#(
    parameter int EXTERNAL_INT_NUM   = 13,
    parameter int UART_OVER_SAMPLING = 16
) (
    input rst_sync,
    // 总线接口部分
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,

    output logic read_finish,
    output logic write_finish,
    output logic [31:0] rdata,
    // 系统外设特殊部分

    // BOOTLOADER
    input [31:0] bootloader_instruction,
    input [31:0] user_instruction,
    output logic [31:0] instruction,
    input download_mode,
    // EINT_CTRL
    input [EXTERNAL_INT_NUM-1:0] irq_source,
    output logic [26:0] custom_int_code,
    output logic mextern_int,
    // SYSTEM_TIMER
    input systemtimer_clk,
    output logic mtimer_int,
    // UART
    input sampling_clk,
    output logic rx_irq,
    input uart_rx,
    output logic uart_tx,
    // 软件中断
    output logic msoftware_int

);
  // 所有外设必须能在一个时钟周期内完成写入
  // 在两个时钟周期内完成读取
  // SystemPeripheral简称SP
  always_ff @(posedge hb_clk) begin
    if (read_finish) begin
      read_finish <= 0;
    end else if (sel.ren) begin
      read_finish <= 1;
    end
  end
  assign write_finish = 1;

  // 完整地址
  wire [SP_ADDR_LEN-1:0] raddr_full = xt_hb.raddr[SP_ADDR_LEN+2-1:2];
  wire [SP_ADDR_LEN-1:0] waddr_full = xt_hb.waddr[SP_ADDR_LEN+2-1:2];
  // 偏移量地址（外设只需要这部分）
  wire [SP_OFFSET_LEN-1:0] raddr = raddr_full[SP_OFFSET_LEN-1:0];
  wire [SP_OFFSET_LEN-1:0] waddr = waddr_full[SP_OFFSET_LEN-1:0];
  wire [SP_ID_LEN-1:0] rid = raddr_full[SP_ADDR_LEN-1:SP_OFFSET_LEN];
  wire [SP_ID_LEN-1:0] wid = waddr_full[SP_ADDR_LEN-1:SP_OFFSET_LEN];


  //----------设备数据选择----------//
  // 96个警告
  localparam int SP_NUM = 5;
  // 设备索引分配
  localparam int IDX_BOOTLOADER = 0, IDX_EINT_CTRL = 1, IDX_SYSTEM_TIMER = 2, IDX_UART = 3, IDX_SOFTWARE_INT = 4;
  // 设备识别符
  localparam bit [SP_ID_LEN-1:0] DEVICE_ID[SP_NUM-1] = {3'd1, 3'd2, 3'd3, 3'd4};
  // 5'b01_XXX_00

  logic [SP_NUM-1:0] id_sel[2];
  MMIO #(
      .ID_WIDTH(SP_ID_LEN),
      .ADDR_NUM(2),
      .DEVICE_NUM(SP_NUM),
      .BASE_ID(DEVICE_ID)
  ) u_MMIO (
      .device_id({rid, wid}),
      .sel(id_sel)
  );
  wire [SP_NUM-1:0] raddr_sel = id_sel[0];
  wire [SP_NUM-1:0] waddr_sel = id_sel[1];

  logic [31:0] sp_data_in[SP_NUM];
  always_comb begin
    rdata = 0;
    for (int i = 0; i < SP_NUM; ++i) begin
      if (raddr_sel[i]) begin
        rdata = sp_data_in[i];
        break;
      end
    end
  end


  sel_t sp_sel[SP_NUM];
  wire [SP_NUM-1:0] enable_rsel = sel.ren && !read_finish ? raddr_sel : 0;
  wire [SP_NUM-1:0] enable_wsel = sel.wen ? waddr_sel : 0;
  generate
    for (genvar i = 0; i < SP_NUM; ++i) begin : gen_sel
      assign sp_sel[i].ren = enable_rsel[i];
      assign sp_sel[i].wen = enable_wsel[i];
    end
  endgenerate

  sys_peripheral_t sys_share;
  always_comb begin
    sys_share.raddr = raddr;
    sys_share.waddr = waddr;
    sys_share.wdata = xt_hb.wdata;
  end


  //----------外设实例----------//
  // 从ROM自举启动和UART程序下载
  HarvardBootloader u_HarvardBootloader (
      .*,
      .sel  (sp_sel[IDX_BOOTLOADER]),
      .rdata(sp_data_in[IDX_BOOTLOADER])
  );

  // 外部中断控制器
  External_INT_Ctrl #(
      .INT_NUM(EXTERNAL_INT_NUM)
  ) u_External_INT_Ctrl (
      .*,
      .sel  (sp_sel[IDX_EINT_CTRL]),
      .rdata(sp_data_in[IDX_EINT_CTRL])
  );


  // mtime和mtimecmp
  SystemTimer u_SystemTimer (
      .*,
      .sel  (sp_sel[IDX_SYSTEM_TIMER]),
      .rdata(sp_data_in[IDX_SYSTEM_TIMER])
  );


  UART_BUS #(
      // 超采样比率(波特率=SAMPLING_CLK/OVER_SAMPLING)
      // 必须为偶数，最小为8
      .OVER_SAMPLING(UART_OVER_SAMPLING)
  ) u_UART (
      .*,
      .sel  (sp_sel[IDX_UART]),
      .rdata(sp_data_in[IDX_UART])
  );

  // 最高位为激活中断，低15位可作为中断原因
  wire sel_t sel_soft_int = sp_sel[IDX_SOFTWARE_INT];
  logic [15:0] msoftware_int_reg;
  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      msoftware_int <= 0;
      msoftware_int_reg <= 0;
    end else if (sel_soft_int.wen && sys_share.waddr == 'd0) begin
      msoftware_int_reg <= sys_share.wdata[15:0];
      msoftware_int <= sys_share.wdata[15];
    end
  end
  logic [15:0] soft_int_rdata;
  assign sp_data_in[IDX_SOFTWARE_INT] = {16'b0, soft_int_rdata};
  always_ff @(posedge hb_clk) begin
    if (sel_soft_int.ren && sys_share.raddr == 'd0) begin
      soft_int_rdata <= msoftware_int_reg;
    end
  end


endmodule
