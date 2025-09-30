// 已弃用，请使用Verilator仿真
// @Deprecated
`timescale 10 ns / 10ns
// `include "./UniversalModule/RISC-V/Defines/XT_BUS.sv"
// `include "./UniversalModule/RISC-V/Defines/CSR_Typedefs.sv"

module tb;
  import XT_BUS::*;
  //----------固定部分----------//
  reg clk;
  reg rst;
  GSR GSR_INST (.GSR(1'b1));
  PUR PUR_INST (.PUR(1'b1));
  reg download_mode;


  always #8 clk = ~clk;

  initial begin
    download_mode <= 0;
    clk <= 1'b1;
    rst <= 1'b1;
    #3;
    rst <= 1'b0;
  end


  //----------寄存器别名----------//
  // X0直接连接硬件0

  wire [31:0] core_reg_x[32];
  assign core_reg_x[0] = 0;
  genvar r;
  generate
    for (r = 1; r < 32; ++r) begin : gen_core_reg
      assign core_reg_x[r] = tb.risc_.u_RISC_V_Core.u_CoreReg.core_reg[r];
    end
  endgenerate


  //----------指令执行----------//
  wire [31:0] instruction = tb.risc_.u_RISC_V_Core.u_InstructionExecute.instruction_id_ex;


  //----------rom ram 初始值----------//
  // localparam string TEST_FILE = "D:/PROJECTS/Electronics/SystemVerilog/MXO2/mem/flash_test";
  localparam string TEST_FILE = "rv32ui-p-jal";
  initial begin
    // $readmemh({"./test_commands/", TEST_FILE, ".txt"}, tb.risc_.u_ByteTriRAM_32bit.u_TriMixedByteRAM.ram);
    // $readmemh({"./test_commands/", TEST_FILE, ".txt"}, tb.risc_.u_ROM.rom);
    // $readmemh({TEST_FILE, ".txt"}, tb.risc_.u_ROM.rom);

    // $readmemh({"./test_commands/", TEST_FILE, ".txt"}, tb.risc_.u_risc_rom.mem);
  end

  // wire [31:0] x3 = tb.risc_.u_RISC_V_Core.u_CoreReg.core_reg[2];
  // wire [31:0] x26 = tb.risc_.u_RISC_V_Core.u_CoreReg.core_reg[25];
  // wire [31:0] x27 = tb.risc_.u_RISC_V_Core.u_CoreReg.core_reg[26];
  initial begin
    // wait (x26 == 32'd1);

    // #20;
    // if (x27 == 32'd1) begin
    //   $display("############################");
    //   $display("######## %s pass  !!!####", TEST_FILE);
    //   $display("############################");
    // end else begin
    //   $display("############################");
    //   $display("########  fail  !!!#########");
    //   $display("############################");
    //   $display("fail testnum = %2d", x3);
    //   for (int r = 0; r < 31; r = r + 1) begin
    //     $display("x%2d register value is %d", r + 1, tb.risc_.u_RISC_V_Core.u_CoreReg.core_reg[r]);
    //   end
    // end
  end

  parameter int GPIO_NUM = 32;
  wire [GPIO_NUM-1:0] gpio;
  wire [         3:0] key_raw = 4'b1111;
  wire [         1:0] sw_raw = 2'b01;
  wire [         7:0] led;
  wire [         8:0] ledsd             [2];
  wire                uart_rx;
  wire                uart_tx;
  wire i2c1_scl, i2c1_sda;
  wire i2c2_scl, i2c2_sda;
  wire spi_scsn;
  wire [1:0] spi_csn;
  wire spi_clk, spi_miso, spi_mosi;
  XT_Soc_Risc_V risc_ (
      .clk_osc(clk),
      .rst_sw (rst),
      .*
  );


  //----------XT_HB总线----------//
  localparam int DOMAIN_NUM = tb.risc_.u_XT_HB.DOMAIN_NUM;
  localparam int MASTER_NUM = tb.risc_.u_XT_HB.MASTER_NUM;
  sel_t domain_sel[DOMAIN_NUM];
  assign domain_sel = tb.risc_.u_XT_HB.domain_sel;
  hb_slave_t xt_hb;
  assign xt_hb = tb.risc_.u_XT_HB.bus;
  wire [MASTER_NUM-1:0] xt_hb_stall = tb.risc_.u_XT_HB.stall_req;
  wire [31:0] hb_rdata = tb.risc_.u_XT_HB.master_rdata;

  //----------XT_LB总线----------//
  // localparam int LB_SLAVE_NUM = tb.risc_.u_XT_LB.SLAVE_NUM;
  wire lb_clk = tb.risc_.u_XT_LB.lb_clk;
  wire [31:0] lb_rdata = tb.risc_.u_XT_LB.rdata;
  lb_slave_t lb_bus;
  assign lb_bus = tb.risc_.u_XT_LB.bus;

  //----------WISHBONE总线----------//
  wire wb_clk_i = tb.risc_.u_WISHBONE_MASTER.wb_clk_i;
  wire wb_cyc_o = tb.risc_.u_WISHBONE_MASTER.wb_cyc_o;
  wire wb_stb_o = tb.risc_.u_WISHBONE_MASTER.wb_stb_o;
  wire wb_we_o = tb.risc_.u_WISHBONE_MASTER.wb_we_o;
  wire wb_ack_i = tb.risc_.u_WISHBONE_MASTER.wb_ack_i;
  wire [7:0] wb_adr_o = tb.risc_.u_WISHBONE_MASTER.wb_adr_o;
  wire [7:0] wb_dat_o = tb.risc_.u_WISHBONE_MASTER.wb_dat_o;
  wire [7:0] wb_dat_i = tb.risc_.u_WISHBONE_MASTER.wb_dat_i;
  wire [7:0] wb_rdata = tb.risc_.u_WISHBONE_MASTER.rdata;



endmodule
