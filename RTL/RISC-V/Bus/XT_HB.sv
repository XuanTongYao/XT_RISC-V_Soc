//----------高速总线控制器----------//
// 总线通过输入的地址来判断要选中的设备
// 主设备不发出片选信号
// 总线请求使用轮询机制，发生死锁时重置到0，可以看作0号主机优先级较高
// 0.1更新 移除单独的读/写使能扇出
// 0.2更新 整合总线信号为结构体
// 0.3更新 轮询仲裁器，完全ACK访问，读/写独立，地址域映射
// 0.4更新 放弃旧的地址域映射，使用设备识别符+地址偏移的MMIO
module XT_HB
  import Utils_Pkg::sel_t;
  import XT_HBUS_Pkg::*;
#(
    parameter int MASTER_NUM = 1,  // 总线上主设备的数量
    parameter int DEVICE_NUM = 2,  // 总线上IO设备的数量
    // 设备基地址(包含，必须在识别符上对齐)，从0开始划分地址空间(所以0不用填)
    parameter int DEVICE_BASE_ADDR[DEVICE_NUM-1]
) (
    input clk,
    input rst_sync,
    input core_stall_n,

    // 高速总线(读写可以被不同不冲突的主设备占用，全双工)
    // 内核的读写请求为最高优先级
    // 高速总线读写
    input hb_master_in_t master_in[MASTER_NUM],
    input [31:0] device_data_in[DEVICE_NUM],
    input [DEVICE_NUM-1:0] read_finish,
    input [DEVICE_NUM-1:0] write_finish,

    output logic [31:0] hb_rdata,
    output hb_slave_t bus,
    output sel_t device_sel[DEVICE_NUM],
    output logic [MASTER_NUM-1:0] read_grant,
    output logic [MASTER_NUM-1:0] write_grant,
    output logic [MASTER_NUM-1:0] stall_req  // 仲裁失败或读写等待，停顿请求
);


  //----------访问等待控制器----------//
  logic [MASTER_NUM-1:0] read_req, write_req;
  logic [MASTER_NUM-1:0] access_req, rw_access_req;
  logic read_stall, write_stall;
  logic [MASTER_NUM-1:0] arbiter_stall;
  always_comb begin
    access_req = read_req | write_req;
    rw_access_req = read_req & write_req;
    arbiter_stall = (write_req & ~write_grant) | (read_req & ~read_grant);
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (!access_req[i]) begin
        stall_req[i] = 0;
      end else if (arbiter_stall[i]) begin
        stall_req[i] = 1;
      end else if (rw_access_req[i]) begin
        stall_req[i] = write_stall || read_stall;
      end else if (read_req[i]) begin
        stall_req[i] = read_stall;
      end else if (write_req[i]) begin
        stall_req[i] = write_stall;
      end else begin
        stall_req[i] = 0;
      end
    end
  end


  //----------总线仲裁器和控制器----------//
  always_comb begin
    for (int i = 0; i < MASTER_NUM; ++i) begin
      read_req[i]  = master_in[i].read;
      write_req[i] = master_in[i].write;
    end
  end
  wire read_busy, write_busy;
  XT_HB_Arbiter #(.DEVICE_NUM(MASTER_NUM)) u_XT_BusArbiter (.*);

  // 主设备总线复用器
  logic hb_ren, hb_wen;
  logic [HB_ADDR_WIDTH-1:0] raddr_mux, waddr_mux;
  assign bus.raddr = raddr_mux;
  assign bus.waddr = waddr_mux;
  always_comb begin
    hb_ren = 0;
    hb_wen = 0;
    raddr_mux = 0;
    waddr_mux = 0;
    bus.wdata = 0;
    bus.write_width = 0;
    // 读通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (read_grant[i]) begin
        hb_ren = master_in[i].read;
        raddr_mux = master_in[i].raddr;
        break;
      end
    end
    // 写通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (write_grant[i]) begin
        hb_wen = master_in[i].write;
        waddr_mux = master_in[i].waddr;
        bus.wdata = master_in[i].wdata;
        bus.write_width = master_in[i].write_width;
        break;
      end
    end
  end



  // 地址映射与片选生成
  logic [DEVICE_NUM-1:0] sel[2];
  MMIO #(
      .ADDR_WIDTH(HB_ADDR_WIDTH),
      .ID_WIDTH  (HB_ID_WIDTH),
      .ADDR_NUM  (2),
      .DEVICE_NUM(DEVICE_NUM),
      .BASE_ADDR (DEVICE_BASE_ADDR)
  ) u_MMIO (
      .addr({raddr_mux, waddr_mux}),
      .sel (sel)
  );
  wire [DEVICE_NUM-1:0] slave_rsel = hb_ren ? sel[0] : 0;
  wire [DEVICE_NUM-1:0] slave_wsel = hb_wen ? sel[1] : 0;
  generate
    for (genvar i = 0; i < DEVICE_NUM; ++i) begin : gen_slaves_sel
      assign device_sel[i].ren = slave_rsel[i];
      assign device_sel[i].wen = slave_wsel[i];
    end
  endgenerate

  // 读写等待控制
  wire read_wait_finish = hb_ren ? ((read_finish & slave_rsel) != 0) : 1;
  wire write_wait_finish = hb_wen ? ((write_finish & slave_wsel) != 0) : 1;
  assign read_stall  = !read_wait_finish;
  assign write_stall = !write_wait_finish;


  // IO设备总线复用器
  always_comb begin
    hb_rdata = 0;
    for (int i = 0; i < DEVICE_NUM; ++i) begin
      if (sel[0][i]) begin
        hb_rdata = device_data_in[i];
        break;
      end
    end
  end

endmodule
