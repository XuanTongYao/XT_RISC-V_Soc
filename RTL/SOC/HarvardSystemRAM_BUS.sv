// 模块: 改进哈佛结构32位系统主存，按字节寻址，仅支持对齐访问
// 功能: 包含一个真双端口RAM(!!!只是实现字节寻址的处理接口，内部例化的RAM不代表拥有功能)
//       A口始终是指令读取接口，B口始终是总线读写接口
//       可以并行访问指令与数据
//       为保证对齐，读取时可能会读取到周围字节的信息，自行截断

//       若基准ID不是0，且跨越多个ID，务必重新计算访问地址！！！
module HarvardSystemRAM_BUS #(
    parameter int RAM_DEPTH = 1024  // 字深度(最大为2^30对应4GB字节)
) (
    // 总线接口
    xt_hbus_if.port hb,
    // 指令接口
    input inst_fetch_clk_en,
    input [31:0] inst_fetch_addr,
    output logic [31:0] inst_fetch
);
  localparam int WIDTH = $clog2(RAM_DEPTH);

  // A口
  wire [WIDTH-1:0] fetch_addr = WIDTH'(inst_fetch_addr >> 2);

  // B口
  // 读优先
  wire ren = hb.ren;
  logic [1:0] read_byte_offset;
  wire [3:0][7:0] byte_rdata;
  always_ff @(posedge hb.clk) begin
    if (hb.read_finish) begin
      hb.read_finish <= 0;
    end else if (ren) begin
      hb.read_finish   <= 1;
      read_byte_offset <= hb.raddr[1:0];
    end
  end


  wire wen = hb.wen && !hb.ren;
  assign hb.write_finish = wen;

  wire [31:0] wdata;
  wire [ 3:0] byte_en;
  AlignedRAM_Adapter u_AlignedRAM_Adapte (
      .write_size       (hb.write_size),
      .write_byte_offset(hb.waddr[1:0]),
      .raw_wdata        (hb.wdata),
      .wdata            (wdata),
      .byte_en          (byte_en),

      .read_byte_offset(read_byte_offset),
      .byte_rdata      (byte_rdata),
      .rdata           (hb.rdata)
  );

  wire [WIDTH-1:0] word_waddr = WIDTH'(hb.waddr >> 2);
  wire [WIDTH-1:0] word_raddr = WIDTH'(hb.raddr >> 2);
  wire [WIDTH-1:0] AddressB = wen ? word_waddr : word_raddr;

  // 省略端口
  wire ResetA = 0, ResetB = 0;
  wire ClockA = hb.clk, ClockB = hb.clk;
  SystemRAM u_SystemRAM (
      .*,
      .DataInA('0),
      .ByteEnA('0),
      .AddressA(fetch_addr),
      .ClockEnA(inst_fetch_clk_en),
      .WrA(1'b0),
      .QA(inst_fetch),

      .DataInB(wdata),
      .ByteEnB(byte_en),
      .AddressB(AddressB),
      .ClockEnB(1'b1),
      .WrB(wen),
      .QB(byte_rdata)
  );


endmodule
