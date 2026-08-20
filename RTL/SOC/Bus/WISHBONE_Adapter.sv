// hb.clk和syscon.clk实际上是同一个时钟
module WISHBONE_Adapter #(
    parameter int PORT_SIZE = 8
) (
    wishbone_syscon_if.port syscon,
    wishbone_if.master wb,

    xt_hbus_if.port hb
);

  // 停止等待
  wire write_mode, ack;
  always_ff @(posedge syscon.clk) begin
    if (hb.read_finish) hb.read_finish <= 0;
    else if (ack && !write_mode) hb.read_finish <= 1;

    if (hb.write_finish) hb.write_finish <= 0;
    else if (ack && write_mode) hb.write_finish <= 1;
  end


  // 启动读写控制
  // 这里等一个周期，等HB的主机走到下一条指令
  logic delay;
  wire  perform = !delay && (hb.ren || hb.wen);
  always_ff @(posedge syscon.clk) begin
    if (ack) delay <= 1;
    else delay <= 0;
  end

  // 读优先
  wire write = !hb.ren;
  logic [PORT_SIZE-1:0] addr;
  always_comb begin
    if (write) addr = hb.waddr[PORT_SIZE-1:0];
    else addr = hb.raddr[PORT_SIZE-1:0];
  end

  WISHBONE_MASTER #(
      .PORT_SIZE(PORT_SIZE)
  ) u_WISHBONE_MASTER (
      .*,
      .wdata(hb.wdata[PORT_SIZE-1:0]),
      .rdata(hb.rdata[PORT_SIZE-1:0])
  );

endmodule
