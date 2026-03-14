module ActRam #(
    parameter int unsigned WORD_DEPTH = 512
) (
    input clk,
    // input clk_en[2],
    input read[2],
    input write[2],
    input [1:0] width[2],
    input [31:0] addr[2],
    input [31:0] wdata[2],
    output logic [31:0] rdata[2]
);
  localparam int WIDTH = $clog2(WORD_DEPTH);

  function automatic logic [WIDTH-1:0] TruncateAddr(logic [31:0] addr);
    return addr[WIDTH-1:0];
  endfunction

  logic [31:0] ram[WORD_DEPTH];
  initial begin
    string firmware_file = "firmware.hex";
    $value$plusargs("firmware=%s", firmware_file);
    $readmemh(firmware_file, ram);  // 从 0 开始全加载
  end

  logic [31:0] true_wdata[2];

  genvar i;
  generate
    for (i = 0; i < 2; ++i) begin : gen_port

      wire [WIDTH-1:0] word_addr = TruncateAddr(addr[i] >> 2);
      // 00:写入1字节  01:写入2字节  10:写入4字节  11:写入8字节
      wire [1:0] access_width = width[i];
      // 取模4 计算字节偏移量[0,3]
      wire [1:0] byte_offset = addr[i][1:0];
      // 掩码
      logic [31:0] write_mask;
      always_comb begin
        write_mask = 0;
        if (access_width == 2'b10) begin
          write_mask = '1;
          true_wdata[i] = wdata[i];
        end else if (access_width == 2'b01) begin
          true_wdata[i] = {wdata[i][15:0], wdata[i][15:0]};
          unique case (byte_offset)
            2'd0: write_mask = {16'b0, 16'hFFFF};
            2'd2: write_mask = {16'hFFFF, 16'b0};
            default: ;
          endcase
        end else begin
          write_mask = {24'b0, 8'hFF} << (byte_offset * 8);
          true_wdata[i] = {24'b0, wdata[i][7:0]} << (byte_offset * 8);
        end
        true_wdata[i] = (true_wdata[i] & write_mask) | (ram[word_addr] & ~write_mask);
      end

      always_ff @(posedge clk) begin
        if (write[i]) begin
          ram[word_addr] <= true_wdata[i];
        end
      end

      logic [3:0][7:0] byte_rdata;
      always_comb begin
        if (write[0] && addr[i] == addr[0]) begin
          byte_rdata = true_wdata[0];
        end else if (write[1] && addr[i] == addr[1]) begin
          byte_rdata = true_wdata[1];
        end else begin
          byte_rdata = ram[word_addr];
        end

        if (read[i]) begin
          if (byte_offset == 2'b01) begin
            rdata[i] = {24'b0, byte_rdata[1]};
          end else if (byte_offset == 2'b11) begin
            rdata[i] = {24'b0, byte_rdata[3]};
          end else if (byte_offset == 2'b10) begin
            rdata[i] = {16'b0, byte_rdata[3], byte_rdata[2]};
          end else begin
            rdata[i] = byte_rdata;
          end
        end else begin
          rdata[i] = 0;
        end
      end
    end
  endgenerate


endmodule
