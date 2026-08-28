// 用于软件中断的msip内存映射寄存器
// msip 长度固定为32位且只有最低位，其余都为0
module SoftwareINT (
    // 总线接口
    xt_hbus32_if.port hb,
    output logic msoftware_int
);

  logic msip_reg;
  assign msoftware_int = msip_reg;
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      msip_reg <= 0;
    end else if (hb.wen && hb.waddr == 'd0) begin
      msip_reg <= hb.wdata[0];
    end
  end

  always_ff @(posedge hb.clk) if (hb.ren && hb.raddr == 'd0) hb.rdata <= 32'(msip_reg);

endmodule
