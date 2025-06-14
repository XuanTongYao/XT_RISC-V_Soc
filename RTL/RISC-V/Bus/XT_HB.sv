//----------高速总线控制器----------//
// 总线通过输入的地址来判断要选中的地址域
// 主设备不发出片选信号
// 总线请求使用轮询机制，发生死锁时重置到0，可以看作0号主机优先级较高
// 0.1更新 移除单独的读/写使能扇出
// 0.2更新 整合总线信号为结构体
// 0.3更新 轮询仲裁器，完全ACK访问，读/写独立，地址域映射
module XT_HB
  import XT_BUS::*;
#(
    parameter int MASTER_NUM = 1,  // 总线上主设备的数量
    parameter int DOMAIN_NUM = 2,  // 总线上地址域的数量
    // 地址域地址分割线，从0开始切分区域，区域结束不包含分割线地址
    parameter int ADDR_SPLIT[DOMAIN_NUM-1]
) (
    input clk,
    input core_stall_n,

    // 高速总线(读写可以被不同不冲突的主设备占用，全双工)
    // 内核的读写请求为最高优先级
    // 高速总线读写
    input hb_master_in_t master_in[MASTER_NUM],
    input [31:0] domain_data_in[DOMAIN_NUM],
    input [DOMAIN_NUM-1:0] read_finish,
    input [DOMAIN_NUM-1:0] write_finish,

    output logic [31:0] hb_rdata,
    output hb_slave_t bus,
    output sel_t domain_sel[DOMAIN_NUM],
    output logic [MASTER_NUM-1:0] read_accept,
    output logic [MASTER_NUM-1:0] write_accept,
    output logic [MASTER_NUM-1:0] stall_req  // 仲裁失败或读写等待，停顿请求
);


  //----------访问等待控制器----------//
  logic [MASTER_NUM-1:0] read_req, write_req;
  logic read_stall, write_stall;
  logic [MASTER_NUM-1:0] arbiter_stall;
  always_comb begin
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if ((read_req[i] && !read_accept[i]) || (write_req[i] && !write_accept[i])) begin
        arbiter_stall[i] = 1;
      end else begin
        arbiter_stall[i] = 0;
      end
    end
  end
  always_comb begin
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (!read_req[i] && !write_req[i]) begin
        stall_req[i] = 0;
      end else if (read_req[i]) begin
        stall_req[i] = arbiter_stall[i] || read_stall;
      end else if (write_req[i]) begin
        stall_req[i] = arbiter_stall[i] || write_stall;
      end else begin
        stall_req[i] = arbiter_stall[i] || write_stall || read_stall;
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
  XT_BusArbiter #(.DEVICE_NUM(MASTER_NUM)) u_XT_BusArbiter (.*);

  // 主设备总线复用器
  logic hb_ren, hb_wen;
  logic [HB_ADDR_WIDTH-1:0] raddr_mux, waddr_mux;
  always_comb begin
    hb_ren = 0;
    hb_wen = 0;
    raddr_mux = 0;
    waddr_mux = 0;
    bus.wdata = 0;
    bus.write_width = 0;
    // 读通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (read_accept[i]) begin
        hb_ren = master_in[i].read;
        raddr_mux = master_in[i].raddr;
        break;
      end
    end
    // 写通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (write_accept[i]) begin
        hb_wen = master_in[i].write;
        waddr_mux = master_in[i].waddr;
        bus.wdata = master_in[i].wdata;
        bus.write_width = master_in[i].write_width;
        break;
      end
    end
  end



  // 地址映射与片选生成
  logic [DOMAIN_NUM-1:0] sel[2];
  logic [MAX_DOMAIN_ADDR_WIDTH-1:0] mapped_addr[2];
  assign bus.raddr = mapped_addr[0];
  assign bus.waddr = mapped_addr[1];
  AddressMapping #(
      .ADDR_WIDTH(HB_ADDR_WIDTH),
      .MAPPED_ADDR_WIDTH(MAX_DOMAIN_ADDR_WIDTH),
      .ADDR_NUM(2),
      .SLICE_NUM(DOMAIN_NUM),
      .SLICE(ADDR_SPLIT)
  ) u_WAddressMapping (
      .addr       ({raddr_mux, waddr_mux}),
      .mapped_addr(mapped_addr),
      .sel        (sel)
  );
  wire [DOMAIN_NUM-1:0] slave_rsel = hb_ren ? sel[0] : 0;
  wire [DOMAIN_NUM-1:0] slave_wsel = hb_wen ? sel[1] : 0;
  generate
    for (genvar i = 0; i < DOMAIN_NUM; ++i) begin : gen_slaves_sel
      assign domain_sel[i].ren = slave_rsel[i];
      assign domain_sel[i].wen = slave_wsel[i];
    end
  endgenerate

  // 读写等待控制
  wire read_wait_finish = (read_finish & slave_rsel) != 0 || !hb_ren;  // || !hb_ren好像可以去掉
  wire write_wait_finish = (write_finish & slave_wsel) != 0 || !hb_wen;
  assign read_stall  = !read_wait_finish;
  assign write_stall = !write_wait_finish;



  // 地址域总线复用器
  always_comb begin
    // TODO 下面综合了一个类优先级选择器，想办法告诉综合器这是个独热码选择器
    // 好像要用独热码的话必须case，而且面积貌似更大
    // 加上break;后变成一个链式结构生成选择信号
    hb_rdata = 0;
    for (int i = 0; i < DOMAIN_NUM; ++i) begin
      if (sel[0][i]) begin
        hb_rdata = domain_data_in[i];
        break;
      end
    end
    // unique case (sel_last)
    //   6'b000_001: bus.rdata = slave_data_in[0];
    //   6'b000_010: bus.rdata = slave_data_in[1];
    //   6'b000_100: bus.rdata = slave_data_in[2];
    //   6'b001_000: bus.rdata = slave_data_in[3];
    //   6'b010_000: bus.rdata = slave_data_in[4];
    //   6'b100_000: bus.rdata = slave_data_in[5];
    //   default: bus.rdata = 0;
    // endcase
  end

endmodule
