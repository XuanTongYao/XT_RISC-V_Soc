// 32bit最高位为激活中断，其余低位可作为中断原因
module SoftwareINT #(
    parameter int REG_LEN = 16
) (
    // 总线接口
    xt_hbus32_device_if.port hb,
    output logic msoftware_int
);

  logic [REG_LEN-1:0] msoftware_int_reg;
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      msoftware_int <= 0;
      msoftware_int_reg <= 0;
    end else if (hb.sel.wen && hb.waddr == 'd0) begin
      msoftware_int <= hb.wdata[31];
      msoftware_int_reg[REG_LEN-1] <= hb.wdata[31];
      msoftware_int_reg[REG_LEN-2:0] <= hb.wdata[REG_LEN-2:0];
    end
  end

  wire sip = msoftware_int_reg[REG_LEN-1];
  wire [REG_LEN-2:0] cause = msoftware_int_reg[REG_LEN-2:0];
  always_ff @(posedge hb.clk) begin
    if (hb.sel.ren && hb.raddr == 'd0) begin
      hb.rdata <= {sip, 31'(cause)};
    end
  end

endmodule
