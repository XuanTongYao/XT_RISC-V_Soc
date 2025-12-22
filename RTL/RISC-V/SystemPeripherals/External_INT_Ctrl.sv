// 0:使能寄存器  4:待处理中断寄存器
module External_INT_Ctrl
  import Utils_Pkg::sel_t;
  import SystemPeripheral_Pkg::*;
#(
    parameter int INT_NUM = 32
) (
    input rst_sync,
    input hb_clk,
    input sys_peripheral_t sys_share,
    input sel_t sel,
    output logic [31:0] rdata,

    input [INT_NUM-1:0] irq_source,

    output logic [30:0] custom_int_code,
    output logic mextern_int

);
  localparam int CUSTOM_CODE_BEGIN = 16;
  localparam int CODE_WIDTH = $clog2(INT_NUM + CUSTOM_CODE_BEGIN);

  logic [INT_NUM-1:0] INT_enable_reg;
  logic [INT_NUM-1:0] INT_pending_reg;
  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      INT_enable_reg  <= 0;
      INT_pending_reg <= 0;
    end else begin
      if (sel.wen && sys_share.waddr == 'd0) begin
        INT_enable_reg <= sys_share.wdata[INT_NUM-1:0];
      end
      INT_pending_reg <= irq_source & INT_enable_reg;
    end
  end


  always_comb begin
    int id;
    for (id = 0; id < INT_NUM; ++id) begin
      if (INT_pending_reg[id]) begin
        break;
      end
    end
    id = id + CUSTOM_CODE_BEGIN;
    mextern_int = |INT_pending_reg;
    custom_int_code = {{(31 - CODE_WIDTH) {1'b0}}, id[CODE_WIDTH-1:0]};
  end



  // 总线读
  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (sys_share.raddr == 'd0) begin
        rdata <= INT_enable_reg;
      end else begin
        rdata <= INT_pending_reg;
      end
    end
  end


endmodule
