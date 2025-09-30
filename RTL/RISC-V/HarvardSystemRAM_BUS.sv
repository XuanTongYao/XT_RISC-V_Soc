// 模块: 改进哈佛架构32位系统RAM，数据存储器按字节寻址
// 功能: 分别包含指令存储器与数据存储器RAM(!!!只是实现字节寻址的处理接口，内部例化的RAM不代表拥有功能)
//       数据存储器(双端口，按字节寻址)只允许对齐访问
//       指令存储器(双端口，按字节寻址)但只允许字对齐访问(为了兼容PC+4)
//       为保证对齐，读取时可能会读取到周围字节的信息，自行截断
// 版本: v0.3
// 作者: 姚萱彤
// <<< 参 数 >>> //
// CLKRATE:        时钟信号频率
//
//
// <<< 端 口 >>> //
// hb_clk:            时钟信号
module HarvardSystemRAM_BUS
  import Utils_Pkg::sel_t;
  import XT_HBUS_Pkg::*;
#(
    parameter int DATA_RAM_DEPTH = 512,  // 字深度(最大为2^30对应4GB字节)
    parameter int INST_RAM_DEPTH = 512
) (
    input hb_clk,
    input inst_fetch_clk_en,

    // 与高速总线
    input hb_slave_t xt_hb,
    input sel_t ram_data_sel,
    input sel_t ram_inst_sel,
    // 数据RAM
    output logic [31:0] ram_data_rdata,
    output logic ram_data_read_finish,
    output logic ram_data_write_finish,

    // 指令RAM
    input [31:0] inst_fetch_addr,
    output logic [31:0] inst_fetch,
    output logic ram_inst_read_finish,
    output logic ram_inst_write_finish
);
  localparam int DATA_WIDTH = $clog2(DATA_RAM_DEPTH * 4);
  localparam int INST_WIDTH = $clog2(INST_RAM_DEPTH * 4);

  //----------写入字节使能----------//
  // 00:写入1字节  01:写入2字节  10:写入4字节  11:写入8字节
  wire  [ 1:0] write_width = xt_hb.write_width;
  // 取模4 计算字节偏移量[0,3]
  wire  [ 1:0] write_byte_offset = xt_hb.waddr[1:0];
  // 字节使能与写入数据
  logic [31:0] byte_en_wdata;
  logic [ 3:0] byte_en;
  always_comb begin
    byte_en = 4'b0;
    byte_en_wdata = xt_hb.wdata;
    if (write_width == 2'b10) begin
      byte_en = 4'b1111;
    end else if (write_width == 2'b01) begin
      byte_en_wdata = {xt_hb.wdata[15:0], xt_hb.wdata[15:0]};
      unique case (write_byte_offset)
        2'd0: byte_en = 4'b0011;
        2'd2: byte_en = 4'b1100;
        default: ;
      endcase
    end else begin
      byte_en_wdata = {4{xt_hb.wdata[7:0]}};
      unique case (write_byte_offset)
        2'd0: byte_en = 4'b0001;
        2'd1: byte_en = 4'b0010;
        2'd2: byte_en = 4'b0100;
        2'd3: byte_en = 4'b1000;
        default: ;
      endcase
    end
  end



  //----------数据存储器----------//
  wire data_wen = ram_data_sel.wen;
  wire data_ren = ram_data_sel.ren;
  always_ff @(posedge hb_clk) begin
    if (ram_data_read_finish) begin
      ram_data_read_finish <= 0;
    end else if (data_ren) begin
      ram_data_read_finish <= 1;
    end
  end
  assign ram_data_write_finish = 1;

  //数据RAM读取
  wire [3:0][7:0] byte_rdata;
  logic [1:0] read_byte_offset;
  always_ff @(posedge hb_clk) begin
    if (data_ren) begin
      read_byte_offset <= xt_hb.raddr[1:0];
    end
  end
  always_comb begin
    if (read_byte_offset == 2'b01) begin
      // 字节对齐
      ram_data_rdata = {24'b0, byte_rdata[1]};
    end else if (read_byte_offset == 2'b11) begin
      // 字节对齐
      ram_data_rdata = {24'b0, byte_rdata[3]};
    end else if (read_byte_offset == 2'b10) begin
      // 半字对齐
      ram_data_rdata = {16'b0, byte_rdata[3], byte_rdata[2]};
    end else if (read_byte_offset == 2'b00) begin
      // 字对齐
      ram_data_rdata = byte_rdata;
    end
  end


  // 除以4计算 字的地址(对齐)
  wire [DATA_WIDTH-1-2:0] data_word_waddr = xt_hb.waddr[DATA_WIDTH-1:0] >> 2;
  wire [DATA_WIDTH-1-2:0] data_word_raddr = xt_hb.raddr[DATA_WIDTH-1:0] >> 2;
  // 省略端口
  wire Reset = 0;
  wire RdClock = hb_clk, WrClock = hb_clk;
  SystemDataRAM u_DataRAM (
      .*,
      .WrAddress(data_word_waddr),
      .RdAddress(data_word_raddr),
      .Data(byte_en_wdata),
      .ByteEn(byte_en),
      .WE(data_wen),
      .RdClockEn(data_ren),
      .WrClockEn(1'b1),
      .Q(byte_rdata)
  );



  //----------指令存储器（只考虑字对齐）----------//
  // TODO 可以换成真双端口的，允许同时两个读
  wire inst_wen = ram_inst_sel.wen;
  wire [INST_WIDTH-1-2:0] inst_word_waddr = xt_hb.waddr[INST_WIDTH-1:0] >> 2;
  wire [INST_WIDTH-1-2:0] inst_word_raddr = xt_hb.raddr[INST_WIDTH-1:0] >> 2;
  wire [INST_WIDTH-1-2:0] fetch_addr = inst_fetch_addr[INST_WIDTH-1:0] >> 2;
  wire [31:0] inst_wdata = xt_hb.wdata;
  assign ram_inst_read_finish  = 1;
  assign ram_inst_write_finish = 1;

  SystemInstructionRAM u_InstructionRAM (
      .*,
      .WrAddress(inst_word_waddr),
      .RdAddress(fetch_addr),
      .Data(inst_wdata),
      .WE(inst_wen),
      .RdClockEn(inst_fetch_clk_en),
      .WrClockEn(inst_fetch_clk_en),
      .Q(inst_fetch)
  );

endmodule
