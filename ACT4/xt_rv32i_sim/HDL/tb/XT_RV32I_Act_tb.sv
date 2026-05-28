module XT_RV32I_Act_tb
  import CoreConfig::CORE_DEFAULT_CFG;
#(
    parameter int unsigned RAM_WORD_DEPTH = 32'h000F_0000,
    parameter int unsigned RAM_BASE_ADDR  = 32'h80000000
) ();

  // 时钟生成(周期为两个时间单位)
  logic clk, rst;
  always begin
    clk = 0;
    #1;
    clk = 1;
    #1;
  end
  // 复位与超时检测逻辑
  initial begin
    rst = 1;
    #4;
    rst = 0;
  end


  // 调试器接口
  dm_hart_minimal_if dm_hart ();
  assign dm_hart.ackhavereset = 0;
  assign dm_hart.haltreq = 0;
  assign dm_hart.resumereq = 0;
  dm_register_if command0 ();
  assign command0.transfer = 0;
  assign command0.write = 0;

  wire stall_req = 0;
  wire core_stall_n;

  instruction_if core_inst_if ();
  memory_direct_if #(
      .DATA_WIDTH(32),
      .ADDR_WIDTH(32)
  ) memory ();

  wire mextern_int = 0;
  wire msoftware_int = 0;
  wire mtimer_int = 0;
  wire [30:0] custom_int_code = 0;
  int_source_if mint (.*);
  RISC_V_Core #(
      .CFG(CORE_DEFAULT_CFG),
      .INST_FETCH_REG(0),
      .STALL_REQ_COUNT(1),
      .PC_RESET(RAM_BASE_ADDR)
  ) dut (
      .*
  );


  ActRam #(
      .WORD_DEPTH(RAM_WORD_DEPTH),
      .BASE_ADDR (RAM_BASE_ADDR)
  ) u_ActRam (
      .*
  );


  // HTIF
  typedef HTIF#(.RAM_WORD_DEPTH(RAM_WORD_DEPTH)) THE_HTIF;
  THE_HTIF htif;
  string   dump_file;
  initial begin
    string wave;
    $value$plusargs("dump=%s", dump_file);
    htif = new(RAM_BASE_ADDR, memory);
    if ($value$plusargs("wave=%s", wave)) begin
      $dumpfile(wave);
      $dumpvars();
    end
  end

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      htif.check_halt = 0;
    end else begin
      htif.capture_write();
    end
  end

  always @(posedge clk) begin
    if (htif.check_timeout_and_plus()) begin
      htif.timeout(u_ActRam.ram);
    end else if (htif.check_halt) begin
      // 转储所有ram数据
      // int fd = $fopen(dump_file, "w");
      // if (fd == 0) $fatal(1,"Failed to open ram dump file");
      // for (int i = 0; i < RAM_WORD_DEPTH; ++i) begin
      //   $fwrite(fd, "%08x: %08x\n", i << 2, u_ActRam.ram[i]);
      // end
      // $fclose(fd);

      htif.finalize(u_ActRam.ram);
    end
  end

endmodule
