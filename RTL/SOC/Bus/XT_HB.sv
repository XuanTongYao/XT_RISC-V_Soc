//----------高速总线控制器----------//
// 总线通过输入的地址来判断要选中的设备
// 主设备不发出片选信号
// 总线请求使用轮询机制，发生死锁时重置到0，可以看作0号主机优先级较高
// 0.1更新 移除单独的读/写使能扇出
// 0.2更新 整合总线信号为结构体
// 0.3更新 轮询仲裁器，完全ACK访问，读/写独立，地址域映射
// 0.4更新 放弃旧的地址域映射，使用设备识别符+地址偏移的MMIO
// 0.5更新 使用接口作为总线信号
// 0.6更新 去除嵌套接口的使用
module XT_HB
  import Utils_Pkg::sel_t;
  import SocConfig::HB_ID_WIDTH;
#(
    parameter int ADDR_WIDTH = 16,
    parameter int ID_WIDTH = 3,
    parameter int MASTER_NUM = 1,  // 总线上主设备的数量
    parameter int DEVICE_NUM = 2,  // 总线上IO设备的数量
    // 设备基准识别符，从0开始划分地址空间(所以0不用填)
    parameter bit [ID_WIDTH-1:0] DEVICE_BASE_ID[DEVICE_NUM-1]
) (
    input clk,
    input rst,

    // 高速总线(读写可以被不同不冲突的主设备占用，全双工)
    // 内核的读写请求为最高优先级
    // 高速总线读写
    memory_direct_if.slave master    [MASTER_NUM],
    xt_hbus_rsp_if.bus     rsp_master[MASTER_NUM],
    xt_hbus_if.bus         devices   [DEVICE_NUM]
);
  localparam int OFFSET_WIDTH = ADDR_WIDTH - ID_WIDTH;

  // 提前声明
  logic [31:0] hb_rdata;

  //----------解包接口----------//
  // 访问接口数组必须使用“常量”，循环变量i都不行
  // 所以必须解包成结构体
  typedef struct packed {
    logic read, write;
    logic [1:0] read_size, write_size;
    logic [ADDR_WIDTH-1:0] raddr, waddr;
    logic [31:0] wdata;
  } master_in_t;
  master_in_t master_in[MASTER_NUM];
  generate
    for (genvar i = 0; i < MASTER_NUM; ++i) begin : gen_unpack_if
      assign master_in[i].read = master[i].read;
      assign master_in[i].write = master[i].write;
      assign master_in[i].read_size = master[i].read_size;
      assign master_in[i].write_size = master[i].write_size;
      assign master_in[i].raddr = master[i].raddr[ADDR_WIDTH-1:0];
      assign master_in[i].waddr = master[i].waddr[ADDR_WIDTH-1:0];
      assign master_in[i].wdata = master[i].wdata;
      assign master[i].rdata = hb_rdata;
    end
  endgenerate


  //----------访问等待控制器----------//
  logic [MASTER_NUM-1:0] read_req, write_req;
  logic [MASTER_NUM-1:0] read_grant, write_grant;

  logic read_finished, write_finished;
  wire [MASTER_NUM-1:0] read_rsp = {MASTER_NUM{read_finished}};
  wire [MASTER_NUM-1:0] write_rsp = {MASTER_NUM{write_finished}};
  logic [MASTER_NUM-1:0] read_stall, write_stall, stall_req;
  always_comb begin
    read_stall  = (read_req & ~read_grant) | (read_req & ~read_rsp);
    write_stall = (write_req & ~write_grant) | (write_req & ~write_rsp);
    stall_req   = read_stall | write_stall;
  end
  generate
    for (genvar i = 0; i < MASTER_NUM; ++i) begin : gen_rsp_if
      assign rsp_master[i].read_grant  = read_grant[i];
      assign rsp_master[i].write_grant = write_grant[i];
      assign rsp_master[i].read_stall  = read_stall[i];
      assign rsp_master[i].write_stall = write_stall[i];
      assign rsp_master[i].stall_req   = stall_req[i];
    end
  endgenerate


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
  logic [ADDR_WIDTH-1:0] raddr_mux, waddr_mux;
  logic [1:0] read_size_mux, write_size_mux;
  logic [31:0] wdata_mux;
  always_comb begin
    hb_ren = 0;
    hb_wen = 0;
    raddr_mux = 0;
    waddr_mux = 0;
    read_size_mux = 0;
    write_size_mux = 0;
    wdata_mux = 0;
    // 读通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (read_grant[i]) begin
        hb_ren = master_in[i].read;
        raddr_mux = master_in[i].raddr;
        read_size_mux = master_in[i].read_size;
        break;
      end
    end
    // 写通道复用器
    for (int i = 0; i < MASTER_NUM; ++i) begin
      if (write_grant[i]) begin
        hb_wen = master_in[i].write;
        waddr_mux = master_in[i].waddr;
        write_size_mux = master_in[i].write_size;
        wdata_mux = master_in[i].wdata;
        break;
      end
    end
  end



  // 片选生成
  logic [DEVICE_NUM-1:0] sel[2];
  wire [ID_WIDTH-1:0] raddr_mux_id = raddr_mux[OFFSET_WIDTH+:ID_WIDTH];
  wire [ID_WIDTH-1:0] waddr_mux_id = waddr_mux[OFFSET_WIDTH+:ID_WIDTH];
  SelectDecoder #(
      .ID_WIDTH(ID_WIDTH),
      .ADDR_NUM(2),
      .DEVICE_NUM(DEVICE_NUM),
      .BASE_ID(DEVICE_BASE_ID)
  ) u_MMIO (
      .device_id('{raddr_mux_id, waddr_mux_id}),
      .sel(sel)
  );
  wire [DEVICE_NUM-1:0] slave_rsel = hb_ren ? sel[0] : 0;
  wire [DEVICE_NUM-1:0] slave_wsel = hb_wen ? sel[1] : 0;



  // 读写等待控制
  logic [DEVICE_NUM-1:0] read_finish, write_finish;
  assign read_finished  = hb_ren ? ((read_finish & slave_rsel) != 0) : 1;
  assign write_finished = hb_wen ? ((write_finish & slave_wsel) != 0) : 1;


  // IO设备总线复用器
  logic [31:0] device_data[DEVICE_NUM];
  always_comb begin
    hb_rdata = 0;
    for (int i = 0; i < DEVICE_NUM; ++i) begin
      if (sel[0][i]) begin
        hb_rdata = device_data[i];
        break;
      end
    end
  end


  generate
    for (genvar i = 0; i < DEVICE_NUM; ++i) begin : gen_device_link
      assign devices[i].clk = clk;
      assign devices[i].rst = rst;
      assign devices[i].read_size = read_size_mux;
      assign devices[i].write_size = write_size_mux;
      assign devices[i].raddr = raddr_mux;
      assign devices[i].waddr = waddr_mux;
      assign devices[i].wdata = wdata_mux;
      assign devices[i].sel.ren = slave_rsel[i];
      assign devices[i].sel.wen = slave_wsel[i];

      assign device_data[i] = devices[i].rdata;
      assign read_finish[i] = devices[i].read_finish;
      assign write_finish[i] = devices[i].write_finish;
    end
  endgenerate

endmodule
