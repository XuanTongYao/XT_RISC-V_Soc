// ResetController和ResetWishboneOverride都是为了解决MXO2芯片的一个问题:
// 开启Flash接口时全局复位(GSR)会被禁用
module ResetWishboneOverride (
    input override,
    output logic idle,
    wishbone_syscon_if.port syscon,
    wishbone_if.slave efb_wb,
    wishbone_if.slave reset_wb,
    wishbone_if.master wb
);

  assign idle = !efb_wb.cyc;

  always_comb begin
    reset_wb.ack = 1'b0;
    efb_wb.ack = 1'b0;
    reset_wb.dat_slave = wb.dat_slave;
    efb_wb.dat_slave = wb.dat_slave;

    if (override) begin
      wb.dat_master = reset_wb.dat_master;
      wb.cyc        = reset_wb.cyc;
      wb.stb        = reset_wb.stb;
      wb.we         = reset_wb.we;
      wb.adr        = reset_wb.adr;
      reset_wb.ack  = wb.ack;
    end else begin
      wb.dat_master = efb_wb.dat_master;
      wb.cyc        = efb_wb.cyc;
      wb.stb        = efb_wb.stb;
      wb.we         = efb_wb.we;
      wb.adr        = efb_wb.adr;
      efb_wb.ack    = wb.ack;
    end
  end

endmodule
