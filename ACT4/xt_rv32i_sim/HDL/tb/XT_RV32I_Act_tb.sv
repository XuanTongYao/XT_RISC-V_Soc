module XT_RV32I_Act_tb #(
    parameter int unsigned RAM_WORD_DEPTH = 32'h000F_0000,
    parameter int unsigned RAM_BASE_ADDR  = 32'h80000000
) (
    input clk,
    input rst_sync
);

  function automatic bit AccessRAM(logic [31:0] addr);
    return RAM_BASE_ADDR <= addr && addr <= RAM_BASE_ADDR + (RAM_WORD_DEPTH * 4);
  endfunction

  wire stall_req = 0;
  wire core_stall_n;

  logic [31:0] instruction;
  wire [31:0] instruction_addr;

  wire access_ram_read;
  wire access_ram_write;
  wire [1:0] access_ram_width;
  wire [31:0] access_ram_raddr;
  logic [31:0] access_ram_rdata;
  wire [31:0] access_ram_wdata;
  wire [31:0] access_ram_waddr;

  wire mextern_int = 0;
  wire msoftware_int = 0;
  wire mtimer_int = 0;
  wire [30:0] custom_int_code = 0;
  RISC_V_Core #(
      .INST_FETCH_REG(0),
      .STALL_REQ_NUM(1),
      .PC_RESET(RAM_BASE_ADDR)
  ) dut (
      .*
  );


  // 0是指令通道
  logic read[2];
  logic write[2];
  logic [1:0] width[2];
  logic [31:0] addr[2];
  logic [31:0] wdata[2];
  wire [31:0] rdata[2];
  wire core_access_ram_read = access_ram_read & AccessRAM(access_ram_raddr);
  wire core_access_ram_write = access_ram_write & AccessRAM(access_ram_waddr);
  always_comb begin
    read = '{1'b1, core_access_ram_read};
    write = '{1'b0, core_access_ram_write};
    width = '{2'b10, access_ram_width};
    addr[0] = instruction_addr - RAM_BASE_ADDR;
    if (access_ram_read) begin
      addr[1] = access_ram_raddr - RAM_BASE_ADDR;
    end else begin
      addr[1] = access_ram_waddr - RAM_BASE_ADDR;
    end
    wdata = '{32'b0, access_ram_wdata};
    instruction = rdata[0];
    access_ram_rdata = rdata[1];
  end
  ActRam #(.WORD_DEPTH(RAM_WORD_DEPTH)) u_ActRam (.*);


  // HTIF
  typedef HTIF#(.RAM_WORD_DEPTH(RAM_WORD_DEPTH)) THE_HTIF;
  THE_HTIF htif;
  string   dump_file;
  initial begin
    string wave;
    $value$plusargs("dump=%s", dump_file);
    htif = new(RAM_BASE_ADDR);
    if ($value$plusargs("wave=%s", wave)) begin
      $dumpfile(wave);
      $dumpvars();
    end
  end

  always @(posedge clk, posedge rst_sync) begin
    if (rst_sync) begin
      htif.check_halt <= 0;
    end else begin
      htif.capture_write(access_ram_write, access_ram_waddr, access_ram_wdata);
    end
  end

  always @(posedge clk) begin
    if (htif.check_timeout_and_plus()) begin
      htif.timeout(u_ActRam.ram);
    end else if (htif.check_halt) begin
      // 转储所有ram数据
      // int fd = $fopen(dump_file, "w");
      // if (fd == 0) begin
      //   $fatal(1,"Failed to open ram dump file");
      // end
      // for (int i = 0; i < RAM_WORD_DEPTH; ++i) begin
      //   $fwrite(fd, "%08x: %08x\n", i << 2, u_ActRam.ram[i]);
      // end
      // $fclose(fd);

      htif.finalize(u_ActRam.ram);
    end
  end

endmodule
