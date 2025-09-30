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
    output logic uart_tx

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
  localparam int SP_NUM = 4;
  // 设备索引分配
  localparam int IDX_BOOTLOADER = 0, IDX_EINT_CTRL = 1, IDX_SYSTEM_TIMER = 2, IDX_UART = 3;
  // 设备识别符
  localparam bit [SP_ID_LEN-1:0] DEVICE_ID[SP_NUM-1] = {2'b01, 2'b10, 2'b11};
  // 5'b01_XXX_00

  // 读取
  logic [SP_NUM-1:0] raddr_sel;
  logic [31:0] sp_data_in[SP_NUM];
  always_comb begin
    raddr_sel = 0;
    raddr_sel[0] = 1;
    for (int j = 1; j < SP_NUM; ++j) begin
      if (rid >= DEVICE_ID[j-1]) begin
        raddr_sel = 0;
        raddr_sel[j] = 1;
      end
    end
  end
  always_comb begin
    rdata = 0;
    for (int i = 0; i < SP_NUM; ++i) begin
      if (raddr_sel[i]) begin
        rdata = sp_data_in[i];
        break;
      end
    end
  end


  // 写入
  logic [SP_NUM-1:0] waddr_sel;
  always_comb begin
    waddr_sel = 0;
    waddr_sel[0] = 1;
    for (int j = 1; j < SP_NUM; ++j) begin
      if (wid >= DEVICE_ID[j-1]) begin
        waddr_sel = 0;
        waddr_sel[j] = 1;
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

endmodule
