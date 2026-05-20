// 对齐主存适配器
// 为仅支持对齐访问的主存，计算相关信号
// write_size定义 -> 00:写入1字节  01:写入2字节  10:写入4字节
module AlignedRAM_Adapter (
    input [1:0] write_size,
    input [1:0] write_byte_offset,
    input [31:0] raw_wdata,
    output logic [31:0] wdata,
    output logic [3:0] byte_en,

    input [1:0] read_byte_offset,
    input [3:0][7:0] byte_rdata,
    output logic [31:0] rdata
);

  //----------写入数据与字节使能----------//
  always_comb begin
    byte_en = 4'b0;
    wdata   = raw_wdata;
    if (write_size == 2'b10) begin
      byte_en = 4'b1111;
    end else if (write_size == 2'b01) begin
      wdata = {raw_wdata[15:0], raw_wdata[15:0]};
      unique case (write_byte_offset)
        2'd0: byte_en = 4'b0011;
        2'd2: byte_en = 4'b1100;
        default: ;
      endcase
    end else begin
      wdata = {4{raw_wdata[7:0]}};
      unique case (write_byte_offset)
        2'd0: byte_en = 4'b0001;
        2'd1: byte_en = 4'b0010;
        2'd2: byte_en = 4'b0100;
        2'd3: byte_en = 4'b1000;
      endcase
    end
  end


  //----------读取数据----------//
  always_comb begin
    unique case (read_byte_offset)
      2'd0: rdata = byte_rdata;  // 字对齐
      2'd1: rdata = 32'(byte_rdata[1]);  // 字节对齐
      2'd2: rdata = 32'({byte_rdata[3], byte_rdata[2]});  // 半字对齐
      2'd3: rdata = 32'(byte_rdata[3]);  // 字节对齐
    endcase
  end

endmodule
