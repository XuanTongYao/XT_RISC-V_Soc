// 模块: 改进哈佛架构32位系统主存，数据存储器按字节寻址
// 功能: 分别包含指令存储器与数据存储器RAM(!!!只是实现字节寻址的处理接口，内部例化的RAM不代表拥有功能)
//       数据存储器(双端口，按字节寻址)只允许对齐访问
//       指令存储器(真双端口，按字节寻址)只允许对齐访问，A口始终是指令读取接口，B口是总线读写接口
//       为保证对齐，读取时可能会读取到周围字节的信息，自行截断
module HarvardSystemRAM_BUS
  import Utils_Pkg::sel_t;
#(
    parameter int DATA_RAM_DEPTH = 512,  // 字深度(最大为2^30对应4GB字节)
    parameter int INST_RAM_DEPTH = 512
) (
    input inst_fetch_clk_en,

    // 数据RAM
    xt_hbus_if.port data_ram,
    // 指令RAM
    xt_hbus_if.port inst_ram,
    input [31:0] inst_fetch_addr,
    output logic [31:0] inst_fetch
);
  localparam int DATA_WIDTH = $clog2(DATA_RAM_DEPTH);
  localparam int INST_WIDTH = $clog2(INST_RAM_DEPTH);

  //----------数据存储器----------//
  wire data_wen = data_ram.sel.wen;
  wire data_ren = data_ram.sel.ren;
  always_ff @(posedge data_ram.clk) begin
    if (data_ram.read_finish) begin
      data_ram.read_finish <= 0;
    end else if (data_ren) begin
      data_ram.read_finish <= 1;
    end
  end
  assign data_ram.write_finish = 1;

  logic [1:0] data_ram_read_byte_offset;
  always_ff @(posedge data_ram.clk) begin
    if (data_ren) data_ram_read_byte_offset <= data_ram.raddr[1:0];
  end

  wire [31:0] data_ram_wdata;
  wire [3:0] data_ram_byte_en;

  wire [3:0][7:0] data_ram_byte_rdata;
  AlignedRAM_Adapter u_AlignedRAM_Adapter_data_ram (
      .write_size       (data_ram.write_size),
      .write_byte_offset(data_ram.waddr[1:0]),
      .raw_wdata        (data_ram.wdata),
      .wdata            (data_ram_wdata),
      .byte_en          (data_ram_byte_en),

      .read_byte_offset(data_ram_read_byte_offset),
      .byte_rdata      (data_ram_byte_rdata),
      .rdata           (data_ram.rdata)
  );


  // 除以4计算 字的地址(对齐)
  wire [DATA_WIDTH-1:0] data_word_waddr = DATA_WIDTH'(data_ram.waddr >> 2);
  wire [DATA_WIDTH-1:0] data_word_raddr = DATA_WIDTH'(data_ram.raddr >> 2);
  // 省略端口
  wire Reset = 0;
  wire RdClock = data_ram.clk, WrClock = data_ram.clk;
  SystemDataRAM u_DataRAM (
      .*,
      .WrAddress(data_word_waddr),
      .RdAddress(data_word_raddr),
      .Data(data_ram_wdata),
      .ByteEn(data_ram_byte_en),
      .WE(data_wen),
      .RdClockEn(data_ren),
      .WrClockEn(1'b1),
      .Q(data_ram_byte_rdata)
  );



  //----------指令存储器----------//
  // A口始终是指令读取接口
  wire [INST_WIDTH-1:0] fetch_addr = INST_WIDTH'(inst_fetch_addr >> 2);
  // B口是总线读写接口

  // 读优先
  wire inst_wen = inst_ram.sel.wen && !inst_ram.sel.ren;
  wire inst_ren = inst_ram.sel.ren;
  always_ff @(posedge inst_ram.clk) begin
    if (inst_ram.read_finish) begin
      inst_ram.read_finish <= 0;
    end else if (inst_ren) begin
      inst_ram.read_finish <= 1;
    end
  end
  assign inst_ram.write_finish = inst_wen;

  logic [1:0] inst_ram_read_byte_offset;
  always_ff @(posedge inst_ram.clk) begin
    if (inst_ren) inst_ram_read_byte_offset <= inst_ram.raddr[1:0];
  end

  wire [31:0] inst_ram_wdata;
  wire [3:0] inst_ram_byte_en;

  wire [3:0][7:0] inst_ram_byte_rdata;
  AlignedRAM_Adapter u_AlignedRAM_Adapter_inst_ram (
      .write_size       (inst_ram.write_size),
      .write_byte_offset(inst_ram.waddr[1:0]),
      .raw_wdata        (inst_ram.wdata),
      .wdata            (inst_ram_wdata),
      .byte_en          (inst_ram_byte_en),

      .read_byte_offset(inst_ram_read_byte_offset),
      .byte_rdata      (inst_ram_byte_rdata),
      .rdata           (inst_ram.rdata)
  );

  wire [INST_WIDTH-1:0] inst_word_waddr = INST_WIDTH'(inst_ram.waddr >> 2);
  wire [INST_WIDTH-1:0] inst_word_raddr = INST_WIDTH'(inst_ram.raddr >> 2);
  wire [INST_WIDTH-1:0] AddressB = inst_wen ? inst_word_waddr : inst_word_raddr;

  // 省略端口
  wire ResetA = 0, ResetB = 0;
  wire ClockA = inst_ram.clk, ClockB = inst_ram.clk;
  SystemInstructionRAM u_InstructionRAM (
      .*,
      .DataInA('0),
      .ByteEnA('0),
      .AddressA(fetch_addr),
      .ClockEnA(inst_fetch_clk_en),
      .WrA(1'b0),
      .QA(inst_fetch),

      .DataInB(inst_ram_wdata),
      .ByteEnB(inst_ram_byte_en),
      .AddressB(AddressB),
      .ClockEnB(1'b1),
      .WrB(inst_wen),
      .QB(inst_ram_byte_rdata)
  );


endmodule
