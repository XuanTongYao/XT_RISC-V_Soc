// 自举启动和下载控制器
// 向寄存器写入0xF0，延迟一个周期(给予PC->0的时间)后切换到用户代码模式
// 寄存器布局
// 0-debug寄存器
// 1-预加载字符串地址 2-预加载字符串
module HarvardBootstrap
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
(
    input rst,
    // 指令选择
    input [31:0] bootloader_instruction,
    input [31:0] user_instruction,
    instruction_if.responder core_inst_if,

    // 总线接口
    input hb_clk,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,

    input download_mode
);
  wire r_debug = sys_share.raddr == 'd0;
  wire w_debug = sys_share.waddr == 'd0;

  // 地址读后自增
  logic [5:0] rom_addr = 0;
  wire [7:0] rom_data;
  rom_str u_rom_str (
      .Address(rom_addr),
      .Q      (rom_data)
  );
  always_ff @(posedge hb_clk) begin
    if (sel.wen && sys_share.waddr == 'd1) begin
      rom_addr <= sys_share.wdata[5:0];
    end else if (sel.ren && sys_share.raddr == 'd2) begin
      rom_addr <= rom_addr + 6'd1;
    end
  end


  //----------运行模式切换----------//
  logic [7:0] debug_reg;
  logic normal_mode;
  always_ff @(posedge hb_clk, posedge rst) begin
    if (rst) begin
      debug_reg   <= 0;
      normal_mode <= 0;
    end else begin
      if (sel.wen && w_debug) debug_reg <= sys_share.wdata[7:0];
      if (!normal_mode && debug_reg == 8'hF1) normal_mode <= 1;
    end
  end

  assign core_inst_if.inst = normal_mode ? user_instruction : bootloader_instruction;

  //----------读寄存器----------//
  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (r_debug) begin
        rdata <= 32'(download_mode);
      end else begin
        rdata <= 32'(rom_data);
      end
    end
  end

endmodule
