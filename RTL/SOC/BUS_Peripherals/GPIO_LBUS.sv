module GPIO_LBUS
  import XT_BUS::*;
#(
    parameter int NUM = 10
) (
    input lb_clk,
    input lb_slave_t xt_lb,
    output logic [NUM-1:0] rdata,

    inout [NUM-1:0] gpio
);
  //方向寄存器0:输入  1:输出
  logic [NUM-1:0] gpio_dir_reg = 0;
  always_ff @(posedge lb_clk) begin
    if (MatchWLB(xt_lb, 8'd4)) begin
      gpio_dir_reg <= xt_lb.wdata;
    end
  end

  //数据寄存器
  logic [NUM-1:0] gpio_data_reg;
  always_ff @(posedge lb_clk) begin
    for (int i = 0; i < NUM; ++i) begin
      if (gpio_dir_reg[i] && MatchWLB(xt_lb, 8'd8)) begin
        gpio_data_reg[i] <= xt_lb.wdata[i];
      end else if (!gpio_dir_reg[i]) begin
        gpio_data_reg[i] <= gpio[i];
      end
    end
  end

  // GPIO控制
  genvar i;
  generate
    for (i = 0; i < NUM; ++i) begin : gen_assign_gpio
      assign gpio[i] = gpio_dir_reg[i] ? gpio_data_reg[i] : 1'bz;
    end
  endgenerate


  always_comb begin
    if (MatchRLB(xt_lb, 8'd4)) begin
      rdata = gpio_dir_reg;
    end else if (MatchRLB(xt_lb, 8'd8)) begin
      rdata = gpio_data_reg;
    end else begin
      rdata = 0;
    end
  end

endmodule
