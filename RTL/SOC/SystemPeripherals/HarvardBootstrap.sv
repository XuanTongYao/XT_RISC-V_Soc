// 自举启动和下载控制器
// 向寄存器写入0xF0，延迟一个周期(给予PC->0的时间)后切换到用户代码模式
// 寄存器布局
// 0-debug寄存器
// 1-预加载字符串地址 2-预加载字符串
module HarvardBootstrap (
    // 指令选择
    input [31:0] bootloader_instruction,
    input [31:0] user_instruction,
    instruction_if.responder core_inst_if,

    // 总线接口
    xt_hbus32_if.port hb,

    input download_mode
);

  // 地址读后自增(使用前必须写入正确地址)
  logic [5:0] rom_addr;
  wire  [7:0] rom_data;
  rom_str u_rom_str (
      .Address(rom_addr),
      .Q      (rom_data)
  );
  always_ff @(posedge hb.clk) begin
    if (hb.wen && hb.waddr == 'd1) begin
      rom_addr <= hb.wdata[5:0];
    end else if (hb.ren && hb.raddr == 'd2) begin
      rom_addr <= rom_addr + 6'd1;
    end
  end


  //----------运行模式切换----------//
  logic [7:0] debug_reg;
  logic normal_mode;
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      debug_reg   <= 0;
      normal_mode <= 0;
    end else begin
      if (hb.wen && hb.waddr == 'd0) debug_reg <= hb.wdata[7:0];
      if (!normal_mode && debug_reg == 8'hF1) normal_mode <= 1;
    end
  end

  assign core_inst_if.inst = normal_mode ? user_instruction : bootloader_instruction;

  //----------读寄存器----------//
  always_ff @(posedge hb.clk) begin
    if (hb.ren) begin
      if (hb.raddr == 'd0) begin
        hb.rdata <= 32'(download_mode);
      end else begin
        hb.rdata <= 32'(rom_data);
      end
    end
  end

endmodule
