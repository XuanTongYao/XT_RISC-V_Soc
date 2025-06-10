// 模块: 哈佛架构32位系统RAM，数据存储器按字节寻址
// 功能: 分别包含指令存储器与数据存储器RAM(!!!只是实现字节寻址的处理接口，内部例化的RAM不代表拥有功能)
//       数据存储器(双端口，按字节寻址)只允许对齐访问
//       指令存储器(双端口，按字节寻址)但只允许字对齐访问(为了兼容PC+4)
//       为保证对齐，读取时可能会读取到周围字节的信息，自行截断
// 版本: v0.2
// 作者: 姚萱彤
// <<< 参 数 >>> //
// CLKRATE:        时钟信号频率
//
//
// <<< 端 口 >>> //
// hb_clk:            时钟信号
module HarvardSystemRAM_BUS
  import XT_BUS::*;
#(
    parameter int DATA_RAM_DEPTH = 512,  // 字深度(最大为2^30对应4GB字节)
    parameter int INST_RAM_DEPTH = 512
) (
    input hb_clk,
    input clk_en,

    // 与高速总线
    input hb_slave_t xt_hb,
    input sel_t ram_sel,
    input sel_t ram_inst,
    // 数据RAM
    output logic [31:0] ram_r_data,
    output logic ram_wait_finish,

    // 指令RAM
    input [$clog2(INST_RAM_DEPTH*4)-1:0] ram_instruction_r_addr,
    output logic [31:0] ram_instruction_r_data,
    output logic ram_instruction_wait_finish

);
  // 数据RAM
  // 要写入的字节数 0:写入1个  1:写入2个  2:写入4个
  wire [1:0] ram_w_byte_num = xt_hb.write_width;
  wire ram_wen = ram_sel.wen;
  wire ram_ren = ram_sel.ren;
  wire [$clog2(DATA_RAM_DEPTH*4)-1:0] ram_w_addr = xt_hb.waddr[$clog2(DATA_RAM_DEPTH*4)-1:0];
  wire [$clog2(DATA_RAM_DEPTH*4)-1:0] ram_r_addr = xt_hb.raddr[$clog2(DATA_RAM_DEPTH*4)-1:0];
  wire [31:0] ram_w_data = xt_hb.wdata;
  logic read_finish = 0;
  always_ff @(posedge hb_clk) begin
    if (read_finish) begin
      read_finish <= 0;
    end else if (ram_sel.ren) begin
      read_finish <= 1;
    end
  end
  assign ram_wait_finish = ram_sel.ren ? read_finish : 1;


  // 指令RAM
  wire ram_instruction_wen = ram_inst.wen;
  wire [$clog2(INST_RAM_DEPTH*4)-1:0] ram_instruction_w_addr = xt_hb.waddr[$clog2(INST_RAM_DEPTH*4)-1:0];
  wire [31:0] ram_instruction_w_data = xt_hb.wdata;
  assign ram_instruction_wait_finish = 1;

  // 除以4计算 字的地址(对齐)
  wire [$clog2(DATA_RAM_DEPTH*4)-1-2:0] w_word_addr = ram_w_addr >> 2;
  wire [$clog2(DATA_RAM_DEPTH*4)-1-2:0] r_word_addr = ram_r_addr >> 2;
  wire [$clog2(INST_RAM_DEPTH*4)-1-2:0] instruction_w_word_addr = ram_instruction_w_addr >> 2;
  wire [$clog2(INST_RAM_DEPTH*4)-1-2:0] instruction_r_word_addr = ram_instruction_r_addr >> 2;
  // 取模4 计算字节偏移量[0,3]
  wire [1:0] w_byte_offset = ram_w_addr[1:0];
  logic [1:0] r_byte_offset;
  always_ff @(posedge hb_clk) begin
    if (ram_ren) begin
      r_byte_offset <= ram_r_addr[1:0];
    end
  end

  //----------数据RAM字节选择与写入----------//
  logic [31:0] word_wdata;
  logic [ 3:0] byte_sel;
  always_comb begin
    byte_sel   = 4'b0;
    word_wdata = ram_w_data;
    if (ram_w_byte_num == 2'b10) begin
      byte_sel = 4'b1111;
    end else if (ram_w_byte_num == 2'b01) begin
      unique case (w_byte_offset)
        2'd0: byte_sel = 4'b0011;
        2'd2: begin
          byte_sel   = 4'b1100;
          word_wdata = {ram_w_data[15:0], ram_w_data[15:0]};
        end
        default: ;
      endcase
    end else begin
      word_wdata = {4{ram_w_data[7:0]}};
      unique case (w_byte_offset)
        2'd0: byte_sel = 4'b0001;
        2'd1: byte_sel = 4'b0010;
        2'd2: byte_sel = 4'b0100;
        2'd3: byte_sel = 4'b1000;
        default: ;
      endcase
    end
  end

  //----------数据RAM读取----------//
  wire [3:0][7:0] byte_rdata;
  always_comb begin
    if (r_byte_offset == 2'b01) begin
      // 字节对齐
      ram_r_data = {24'b0, byte_rdata[1]};
    end else if (r_byte_offset == 2'b11) begin
      // 字节对齐
      ram_r_data = {24'b0, byte_rdata[3]};
    end else if (r_byte_offset == 2'b10) begin
      // 半字对齐
      ram_r_data = {16'b0, byte_rdata[3], byte_rdata[2]};
    end else if (r_byte_offset == 2'b00) begin
      // 字对齐
      ram_r_data = byte_rdata;
    end
  end

  // 省略端口
  wire Reset = 0;
  wire RdClock = hb_clk, WrClock = hb_clk;
  wire WrClockEn = clk_en, RdClockEn = ram_ren, ClockEn = 1;
  SystemDataRAM u_DataRAM (
      .*,
      .WrAddress(w_word_addr),
      .RdAddress(r_word_addr),
      .Data(word_wdata),
      .ByteEn(byte_sel),
      .WE(ram_wen),
      .Q(byte_rdata)
  );



  //----------指令存储器（只考虑字对齐）----------//
  SystemInstructionRAM u_InstructionRAM (
      .*,
      .WE(ram_instruction_wen),
      .WrAddress(instruction_w_word_addr),
      .RdAddress(instruction_r_word_addr),
      .Data(ram_instruction_w_data),
      .RdClockEn(clk_en),
      .WrClockEn(clk_en),
      .Q(ram_instruction_r_data)
  );

endmodule
