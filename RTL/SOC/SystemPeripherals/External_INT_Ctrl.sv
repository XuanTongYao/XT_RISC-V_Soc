// 0:中断启用寄存器  4:待处理中断寄存器
module External_INT_Ctrl #(
    parameter int INT_COUNT = 32
) (
    // 总线接口
    xt_hbus32_if.port hb,

    input [INT_COUNT-1:0] irq_source,
    output logic [30:0] custom_int_code,
    output logic mextern_int
);
  localparam int CUSTOM_CODE_BEGIN = 16;
  localparam int CODE_WIDTH = $clog2(INT_COUNT + CUSTOM_CODE_BEGIN);

  logic [INT_COUNT-1:0] INT_enable_reg;
  logic [INT_COUNT-1:0] INT_pending_reg;
  always_ff @(posedge hb.clk, posedge hb.rst) begin
    if (hb.rst) begin
      INT_enable_reg  <= 0;
      INT_pending_reg <= 0;
    end else begin
      if (hb.wen && hb.waddr == 'd0) begin
        INT_enable_reg <= hb.wdata[INT_COUNT-1:0];
      end
      INT_pending_reg <= irq_source & INT_enable_reg;
    end
  end


  always_comb begin
    int id;
    for (id = 0; id < INT_COUNT; ++id) begin
      if (INT_pending_reg[id]) begin
        break;
      end
    end
    id = id + CUSTOM_CODE_BEGIN;
    mextern_int = |INT_pending_reg;
    custom_int_code = 31'(id[CODE_WIDTH-1:0]);
  end



  // 总线读
  always_ff @(posedge hb.clk) begin
    if (hb.ren) begin
      if (hb.raddr == 'd0) begin
        hb.rdata <= 32'(INT_enable_reg);
      end else begin
        hb.rdata <= 32'(INT_pending_reg);
      end
    end
  end


endmodule
