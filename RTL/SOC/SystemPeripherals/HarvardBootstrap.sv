// 自举启动和下载控制器
// 向寄存器写入0xF0，延迟一个周期(给予PC->0的时间)后切换到用户代码模式
// 寄存器布局
// 0-debug寄存器
// 1-预加载字符串地址 2-预加载字符串
module HarvardBootstrap
  import Rom_Pkg::*;
(
    // 指令选择
    input [31:0] boot_instruction,
    input [31:0] user_instruction,
    instruction_if.responder core_inst_if,

    // 总线接口
    xt_hbus32_if.port hb,

    input download_key,

    output logic reset_req
);

  // 地址读后自增(使用前必须写入正确地址)
  logic [5:0] rom_addr;
  wire  [7:0] rom_data;
  ROM #(
      .DEPTH(PRELOAD_STR_DEPTH),
      .WIDTH(PRELOAD_STR_WIDTH),
      .DATA (PRELOAD_STR)
  ) u_ROM (
      .address(rom_addr),
      .q      (rom_data)
  );
  always_ff @(posedge hb.clk) begin
    if (hb.wen && hb.waddr == 'd1) begin
      rom_addr <= hb.wdata[5:0];
    end else if (hb.ren && hb.raddr == 'd2) begin
      rom_addr <= rom_addr + 6'd1;
    end
  end


  //----------指令映射模式----------//
  localparam bit [7:0] INTO_RAM_MODE = 8'h00;
  localparam bit [7:0] INTO_ROM_MODE = 8'h55;
  logic update_map;
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      reset_req  <= 0;
      update_map <= 1;
    end else begin
      if (update_map) update_map <= 0;
      if (hb.wen && hb.waddr == 'd0 && (hb.wdata[7:0] == INTO_RAM_MODE || hb.wdata[7:0] == INTO_ROM_MODE)) begin
        reset_req <= 1;
      end
    end
  end

  logic into_ram_mode = 0;
  logic into_rom_mode = 0;
  logic mapped_to_ram = 0;
  always_ff @(posedge hb.clk) begin
    if (update_map && (into_ram_mode || into_rom_mode)) begin
      into_ram_mode <= 0;
      into_rom_mode <= 0;
      mapped_to_ram <= into_rom_mode ? 1'b0 : 1'b1;  // rom模式优先级更高
    end else if (hb.wen && hb.waddr == 'd0) begin
      if (hb.wdata[7:0] == INTO_RAM_MODE) begin
        into_ram_mode <= 1;
      end else if (hb.wdata[7:0] == INTO_ROM_MODE) begin
        into_rom_mode <= 1;
      end
    end
  end

  assign core_inst_if.inst = mapped_to_ram ? user_instruction : boot_instruction;

  //----------读寄存器----------//
  always_ff @(posedge hb.clk) begin
    if (hb.ren) begin
      if (hb.raddr == 'd0) begin
        hb.rdata <= 32'(download_key);
      end else begin
        hb.rdata <= 32'(rom_data);
      end
    end
  end

endmodule
