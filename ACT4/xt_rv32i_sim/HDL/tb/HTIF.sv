`define STRICT_PLUSARG(fmt, var) \
    if (!$value$plusargs(fmt, var)) \
        $fatal(1, "%s plusarg not found!",fmt); \

class HTIF #(
    parameter int unsigned RAM_WORD_DEPTH = 32'h000F_0000
);
  virtual memory_direct_if memory;

  string elf_name, signature_file, log_file;
  int unsigned cur_cycles = 0, max_cycles = 1000;
  int unsigned ram_base_addr, tohost_addr;
  int unsigned begin_signature, end_signature;
  logic [31:0] tohost_0, tohost_1;
  logic check_halt;

  function new(int unsigned ram_base_addr, virtual memory_direct_if memory_access);
    `STRICT_PLUSARG("elf_name=%s", elf_name);
    $value$plusargs("max_cycles=%d", max_cycles);
    `STRICT_PLUSARG("tohost=%x", tohost_addr);
    `STRICT_PLUSARG("sig_begin_canary=%x", begin_signature);
    `STRICT_PLUSARG("sig_end_canary=%x", end_signature);
    `STRICT_PLUSARG("signature=%s", signature_file);
    `STRICT_PLUSARG("log=%s", log_file);
    check_halt = 0;
    this.ram_base_addr = ram_base_addr;
    this.memory = memory_access;
  endfunction

  function void capture_write();
    if (memory.write && memory.waddr == tohost_addr) begin
      tohost_0 = memory.wdata;
    end else if (memory.write && memory.waddr == (tohost_addr + 4)) begin
      tohost_1   = memory.wdata;
      check_halt = 1;
    end
  endfunction

  // 返回1，超时，否则不超时
  function bit check_timeout_and_plus();
    cur_cycles++;
    return cur_cycles >= max_cycles;
  endfunction

  function void timeout(ref logic [31:0] ram[RAM_WORD_DEPTH]);
    $display("\nTest %s \033[0;33mTIMEOUT\033[0m\t\tTIME: clk cycles = %d", elf_name, cur_cycles);
    save_log("TIMEOUT");
    save_signature(ram);
    $finish;
  endfunction

  function void finalize(ref logic [31:0] ram[RAM_WORD_DEPTH]);
    if (check_halt) begin
      if (tohost_0 == 32'd1) begin
        $display("\nTest %s \033[0;32mSUCCESS\033[0m\t\tTIME: clk cycles = %d", elf_name, cur_cycles);
        save_log("SUCCESS");
      end else begin
        $display("\nTest %s \033[1;31mFAILED\033[0m\t\tTIME: clk cycles = %d", elf_name, cur_cycles);
        save_log("FAILED");
      end

      save_signature(ram);
      $finish;
    end
  endfunction

  function void save_log(string result);
    int fd = $fopen(log_file, "w");
    if (fd == 0) begin
      $fatal("Failed to open log file");
    end

    $fdisplay(fd, "using %s for test-signature output.", signature_file);
    $fdisplay(fd, "");
    $fdisplay(fd, "RVCP-SUMMARY: Test File \"%s.S\": SIGRUN", elf_name);
    $fdisplay(fd, "HTIF located at 0x%08x", tohost_addr);
    $fdisplay(fd, "begin_signature: 0x%08x", begin_signature);
    // 我也不知道为什么要-4，官方的签名文件就是这样的
    $fdisplay(fd, "end_signature: 0x%08x", end_signature - 4);
    $fdisplay(fd, "Entry point: 0x%08x", ram_base_addr);
    $fdisplay(fd, result);

    $fclose(fd);
  endfunction

  function void save_signature(ref logic [31:0] ram[RAM_WORD_DEPTH]);
    int unsigned start_addr = (begin_signature - ram_base_addr) >> 2;
    int unsigned finish_addr = (end_signature - ram_base_addr) >> 2;
    // 官方的签名文件不包含begin_signature，不知道为什么，之前riscof框架是包含的
    $writememh(signature_file, ram, start_addr + 1, finish_addr - 1);
  endfunction


endclass
