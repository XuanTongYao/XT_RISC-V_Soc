// 仅支持单次读写，有原子指令再考虑支持RMW，正在思考正确的RMW如何实现
// Q:如果有多个设备(比如DMA)要使用WISHBONE资源怎么办？
// A:给每个设备单独配一个主机，避开访问冲突问题。
module WISHBONE_MASTER #(
    parameter int PORT_SIZE = 8
) (
    wishbone_syscon_if.port syscon,
    wishbone_if.master wb,

    input logic perform,
    input logic write,
    input logic [PORT_SIZE-1:0] addr,
    input logic [PORT_SIZE-1:0] wdata,
    output logic [PORT_SIZE-1:0] rdata,
    output logic write_mode,
    output logic ack
);

  assign ack = wb.ack && wb.stb;
  assign write_mode = wb.we;

  always_ff @(posedge syscon.clk) begin
    if (syscon.rst) begin
      wb.stb <= 0;
      wb.cyc <= 0;
    end else begin
      if (wb.cyc) begin  // 进行中
        if (wb.ack) begin
          wb.stb <= 0;
          wb.cyc <= 0;
        end
      end else if (perform) begin  // 空闲
        wb.stb <= 1;
        wb.cyc <= 1;
      end
    end
  end

  always_ff @(posedge syscon.clk) begin
    if (wb.cyc) begin  // 进行中
      if (wb.ack) begin
        if (!wb.we) rdata <= wb.dat_slave;  // 读周期
      end
    end else if (perform) begin  // 空闲
      wb.we  <= write;
      wb.adr <= addr;
      if (write) wb.dat_master <= wdata;
    end
  end

endmodule
