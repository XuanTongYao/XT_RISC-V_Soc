module ActRam #(
    parameter int unsigned WORD_DEPTH = 512,
    parameter int unsigned BASE_ADDR  = 32'h80000000
) (
    input clk,
    instruction_if.responder core_inst_if,
    memory_direct_if.slave memory
);
  localparam int WIDTH = $clog2(WORD_DEPTH);

  function automatic bit Access(logic [31:0] addr);
    return BASE_ADDR <= addr && addr <= BASE_ADDR + (WORD_DEPTH * 4);
  endfunction

  logic [31:0] ram[WORD_DEPTH];
  initial begin
    string firmware_file = "firmware.hex";
    $value$plusargs("firmware=%s", firmware_file);
    $readmemh(firmware_file, ram);  // 从 0 开始全加载
  end


  wire read_enable = memory.read && Access(memory.raddr);
  wire write_enable = memory.write && Access(memory.waddr);
  wire [WIDTH-1:0] read_word_addr = WIDTH'(memory.raddr >> 2);
  wire [WIDTH-1:0] write_word_addr = WIDTH'(memory.waddr >> 2);

  logic [3:0] byte_enable;
  logic [31:0] true_wdata, wdata;
  always_comb begin
    logic [31:0] write_mask = 0;
    for (int i = 0; i < 4; ++i) begin
      write_mask |= (32'({8{byte_enable[i]}}) << i * 8);
    end
    true_wdata = (wdata & write_mask) | (ram[write_word_addr] & ~write_mask);
  end

  always_ff @(posedge clk) begin
    if (write_enable) ram[write_word_addr] <= true_wdata;
  end

  always_comb begin
    byte_enable = 0;
    if (memory.write_size == 2'b10) begin
      wdata = memory.wdata;
      byte_enable = 4'b1111;
    end else if (memory.write_size == 2'b01) begin
      wdata = {2{memory.wdata[15:0]}};
      byte_enable = 4'b0011 << memory.waddr[1:0];
      // 地址取模4 计算字节偏移量[0,3]
    end else begin
      wdata = {4{memory.wdata[7:0]}};
      byte_enable = 4'b0001 << memory.waddr[1:0];
    end
  end


  always_comb begin
    logic [31:0] true_rdata;
    if (write_enable && memory.raddr == memory.waddr) begin
      true_rdata = true_wdata;
    end else begin
      true_rdata = ram[read_word_addr];
    end

    if (read_enable) begin
      // 地址取模4 字节偏移量
      memory.rdata = true_rdata >> (memory.raddr[1:0] * 8);
    end else begin
      memory.rdata = 0;
    end
  end


  // 指令接口
  wire inst_enable = core_inst_if.enable && Access(core_inst_if.addr);
  wire [WIDTH-1:0] inst_word_addr = WIDTH'(core_inst_if.addr >> 2);
  always_comb begin
    if (inst_enable) begin
      if (write_enable && core_inst_if.addr == memory.waddr) begin
        core_inst_if.inst = true_wdata;
      end else begin
        core_inst_if.inst = ram[inst_word_addr];
      end
    end else begin
      core_inst_if.inst = 0;
    end
  end

endmodule
