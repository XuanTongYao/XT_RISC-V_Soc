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
    // 自定义中断代码，大于等于16的部分，只有27位，原来的代码最长也只有31位
    output logic [26:0] custom_int_code,
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
    end else if (sel.wen && xt_hb.waddr[4:2] == 3'd3) begin
      INT_enable_reg <= xt_hb.wdata[INT_NUM-1:0];
    end
  end


  logic [INT_NUM-1:0] INT_pending_reg;
  logic [5:0] int_id;
  always_comb begin
    int id;
    id = 0;
    int_id = 0;
    for (int i = 0; i < INT_NUM; ++i) begin
      if (INT_pending_reg[i]) begin
        id = i + 1;
        int_id = id[5:0];
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
    custom_int_code <= {21'b0, int_id};
  end



  // 总线读
  always_ff @(posedge hb_clk) begin
    if (sel.ren) begin
      if (xt_hb.waddr[4:2] == 3'd3) begin
        rdata <= INT_enable_reg;
      end else begin
        rdata <= INT_pending_reg;
      end
    end
  end


endmodule
