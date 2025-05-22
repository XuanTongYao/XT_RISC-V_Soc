// 0:使能寄存器  4:待处理中断寄存器
import XT_BUS::*;
module External_INT_Ctrl #(
    parameter int INT_NUM = 32
) (
    input rst_sync,
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,
    output logic [31:0] rdata,

    input [INT_NUM-1:0] irq_source,
    output logic [30:0] mextern_int_id,
    output logic mextern_int

);

  // logic [INT_NUM-1:0] INT_delay_reg;
  // always_ff @(posedge hb_clk) begin
  //   INT_delay_reg <= irq_source;
  // end


  logic [INT_NUM-1:0] INT_enable_reg;
  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      INT_enable_reg <= 0;
    end else if (sel.wen && xt_hb.waddr[2:0] == 3'd0) begin
      INT_enable_reg <= xt_hb.wdata[INT_NUM-1:0];
    end
  end


  logic [INT_NUM-1:0] INT_pending_reg;
  logic [5:0] int_id;
  always_comb begin
    int_id = 0;
    for (int i = 0; i < INT_NUM; ++i) begin
      if (INT_pending_reg[i]) begin
        int_id = i;
        break;
      end
    end
  end
  always_ff @(posedge hb_clk) begin
    if (rst_sync) begin
      INT_pending_reg <= 0;
      mextern_int <= 0;
    end else begin
      INT_pending_reg <= irq_source & INT_enable_reg;
      mextern_int <= |INT_pending_reg;
    end
    mextern_int_id <= 6'd16 + int_id;
  end



  // 总线读
  always_ff @(posedge hb_clk) begin
    if (!sel.ren) begin
      rdata <= 0;
    end else begin
      if (xt_hb.raddr[2:0] == 3'd0) begin
        rdata <= INT_enable_reg;
      end else begin
        rdata <= INT_pending_reg;
      end
    end
  end


endmodule
