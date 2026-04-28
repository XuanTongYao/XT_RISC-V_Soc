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
    return BASE_ADDR <= addr && addr < BASE_ADDR + (WORD_DEPTH * 4);
  endfunction

  logic [3:0][7:0] ram[WORD_DEPTH];
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
  logic [31:0] wdata;
  always_ff @(posedge clk) begin
    if (write_enable) begin
      for (int i = 0; i < 4; ++i) begin
        if (byte_enable[i]) ram[write_word_addr][i] <= wdata[i*8+:8];
      end
    end
  end

  always_comb begin
    // 地址取模4 计算字节偏移量[0,3]
    wdata = memory.wdata << (memory.waddr[1:0] * 8);
    if (memory.write_size == 2'b10) begin
      byte_enable = 4'b1111;
    end else if (memory.write_size == 2'b01) begin
      byte_enable = 4'b0011 << memory.waddr[1:0];
    end else begin
      byte_enable = 4'b0001 << memory.waddr[1:0];
    end
  end


  always_comb begin
    if (read_enable) begin
      // 地址取模4 字节偏移量
      memory.rdata = ram[read_word_addr] >> (memory.raddr[1:0] * 8);
    end else begin
      memory.rdata = 0;
    end
  end


  // 指令接口
  wire inst_enable = core_inst_if.enable && Access(core_inst_if.addr);
  wire [WIDTH-1:0] inst_word_addr = WIDTH'(core_inst_if.addr >> 2);
  always_comb begin
    if (inst_enable) begin
      core_inst_if.inst = ram[inst_word_addr];
    end else begin
      core_inst_if.inst = 0;
    end
  end

endmodule
