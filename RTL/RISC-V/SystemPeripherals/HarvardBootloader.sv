// 自举启动和下载控制器
// 向寄存器写入0xF0，延迟一个周期(给予PC->0的时间)后切换到用户代码模式
module HarvardBootloader
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
(
    input rst_sync,
    // 指令选择
    input [31:0] bootloader_instruction,
    input [31:0] user_instruction,
    output logic [31:0] instruction,

    // 总线接口
    input hb_clk,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,

    input download_mode
);
  wire r_debug = sys_share.raddr == 'd0;
  wire r_str = sys_share.raddr == 'd2;
  wire w_debug = sys_share.waddr == 'd0;
  wire w_str_addr = sys_share.waddr == 'd1;

  // 地址读后自增
  logic [5:0] rom_addr = 0;
  logic [5:0] rom_addr_bypass;
  wire [7:0] rom_data;
  rom_str u_rom_str (
      .Address(rom_addr_bypass),
      .Q      (rom_data)
  );
  always_comb begin
    if (sel.wen && w_str_addr) begin
      rom_addr_bypass = sys_share.wdata[5:0];
    end else begin
      rom_addr_bypass = rom_addr;
    end
  end
  always_ff @(posedge hb_clk) begin
    if (sel.wen && w_str_addr) begin
      rom_addr <= sys_share.wdata[5:0];
    end else if (sel.ren && r_str) begin
      rom_addr <= rom_addr + 1'b1;
    end
  end


  //----------运行模式切换----------//
  logic [7:0] debug_reg = 0;
  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      debug_reg <= 0;
    end else if (sel.wen && w_debug) begin
      debug_reg <= sys_share.wdata[7:0];
    end
  end

  typedef enum bit {
    BOOT   = 0,
    NORMAL = 1
  } run_mode_e;

  run_mode_e run_mode;
  always_comb begin
    if (run_mode == BOOT) begin
      instruction = bootloader_instruction;
    end else begin
      instruction = user_instruction;
    end
  end

  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      run_mode <= BOOT;
    end else if (run_mode == BOOT && debug_reg == 8'hF0) begin
      run_mode <= NORMAL;
    end
  end


  //----------读寄存器----------//
  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (r_debug) begin
        rdata <= {24'b0, 7'b0, download_mode};
      end else begin
        rdata <= {24'b0, rom_data};
      end
    end
  end

endmodule
