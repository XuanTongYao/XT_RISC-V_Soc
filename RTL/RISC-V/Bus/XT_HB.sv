//----------高速总线控制器----------//
// 总线通过输入的地址来判断要片选的设备
// 主设备不发出片选信号
// 默认总线请求的最高优先级从0开始
// 0.1更新 移除单独的读/写使能扇出
// 0.2更新 整合总线信号为结构体
module XT_HB
  import XT_BUS::*;
#(
    parameter int MASTER_NUM = 1,  // 总线上主设备的数量(包括核心)
    parameter int SLAVE_NUM = 2,  // 总线上从设备的数量(包括RAM)
    parameter int WAIT_NUM = 0,  // 总线上需要核心等待才能完成操作设备的数量
    // 从设备地址分割线，从0开始切分区域，区域结束不包含分割线地址
    parameter int ADDR_SPLIT[SLAVE_NUM-1]
) (
    input clk,
    input core_stall_n,

    // 与内核
    output logic stall_req,

    // 高速总线(一次只允许一个主设备占用，全双工)
    // 内核的读写请求为最高优先级
    // 高速总线读写
    // master输入第0个固定为CPU内核，每次访存都要经过仲裁
    input [MASTER_NUM-1:0] master_req_in,
    input hb_master_in_t master_in[MASTER_NUM],
    input [31:0] slave_data_in[SLAVE_NUM],
    input [SLAVE_NUM-1:0] wait_finish,

    output logic [31:0] master_rdata,
    output hb_slave_t bus,
    output sel_t slave_sel[SLAVE_NUM],
    output logic [MASTER_NUM-1:0] master_accept
);




  //----------内核访存控制器----------//
  logic write_stall;
  logic read_stall;
  logic arbiter_stall;
  assign stall_req = arbiter_stall | write_stall | read_stall;
  wire core_req = master_req_in[0];
  wire core_accept = master_accept[0];

  // 内核停止控制
  always_comb begin
    if (!core_accept && core_req) begin
      arbiter_stall = 1;
    end else begin
      arbiter_stall = 0;
    end
  end


  //----------总线仲裁器和控制器----------//
  logic bus_busy;
  XT_BusArbiter #(
      .DEVICE_NUM(MASTER_NUM)
  ) u_XT_WBusArbiter (
      .*,
      .bus_req   (master_req_in),
      .bus_accept(master_accept),
      .busy      (bus_busy)
  );
  // 在解码阶段可以知道要不要读取

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
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (master_accept[i]) begin
        hb_ren = master_in[i].read;
        hb_wen = master_in[i].write;
        raddr_mux = master_in[i].raddr;
        waddr_mux = master_in[i].waddr;
        bus.wdata = master_in[i].wdata;
        bus.write_width = master_in[i].write_width;
        break;
      end
    end
  end

  // 地址映射与片选生成
  logic [SLAVE_NUM-1:0] sel[2];
  logic [HB_SLAVE_ADDR_WIDTH-1:0] mapped_addr[2];
  assign bus.raddr = mapped_addr[0];
  assign bus.waddr = mapped_addr[1];
  AddressMapping #(
      .ADDR_WIDTH(HB_ADDR_WIDTH),
      .MAPPED_ADDR_WIDTH(HB_SLAVE_ADDR_WIDTH),
      .ADDR_NUM(2),
      .SLICE_NUM(SLAVE_NUM),
      .SLICE(ADDR_SPLIT)
  ) u_WAddressMapping (
      .addr       ({raddr_mux, waddr_mux}),
      .mapped_addr(mapped_addr),
      .sel        (sel)
  );
  wire [SLAVE_NUM-1:0] slave_rsel = bus_busy && hb_ren ? sel[0] : 0;
  wire [SLAVE_NUM-1:0] slave_wsel = bus_busy && hb_wen ? sel[1] : 0;


  // 内核等待控制
  // wire retired = core_stall_n;  // 指令正常退役
  wire read_wait_finish = (wait_finish & slave_rsel) != 0 || !hb_ren;
  wire write_wait_finish = (wait_finish & slave_wsel) != 0 || !hb_wen;
  bit read_finish = 0;  // 读操作必须停顿一周期
  assign write_stall = !write_wait_finish;
  assign read_stall  = hb_ren && !read_finish;

  bit frame_finish;  // 访问帧是否完成
  always_comb begin
    if (!hb_wen && !hb_ren) begin
      frame_finish = 1;
    end else begin
      frame_finish = hb_wen ? write_wait_finish : read_finish;
    end
  end
  always_ff @(posedge clk) begin
    if (frame_finish) begin
      read_finish <= 0;
    end else if (read_wait_finish) begin
      read_finish <= 1;
    end
  end

  wire [SLAVE_NUM-1:0] out_slave_rsel = read_stall ? slave_rsel : 0;
  wire [SLAVE_NUM-1:0] out_slave_wsel = !read_stall ? slave_wsel : 0;
  generate
    for (genvar i = 0; i < SLAVE_NUM; ++i) begin : gen_slaves_sel
      assign slave_sel[i].ren = out_slave_rsel[i];
      assign slave_sel[i].wen = out_slave_wsel[i];
    end
  endgenerate



  // 从设备总线复用器
  // 片选延迟一个时钟周期与数据同步
  logic [SLAVE_NUM-1:0] sel_last;
  always_ff @(posedge clk) begin
    sel_last <= sel[0];
  end
  always_comb begin
    // TODO 下面综合了一个类优先级选择器，想办法告诉综合器这是个独热码选择器
    // 好像要用独热码的话必须case，而且面积貌似更大
    // 加上break;后变成一个链式结构生成选择信号
    master_rdata = 0;
    for (int i = 0; i < SLAVE_NUM; ++i) begin
      if (sel_last[i]) begin
        master_rdata = slave_data_in[i];
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
