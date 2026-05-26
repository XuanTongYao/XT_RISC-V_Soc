// 寄存器布局
// 0 key_reg
// 1 switch_reg
module SW_KEY_LBUS (
    xt_lbus_if.port lb,
    input [3:0] key_raw,
    input [2:0] sw_raw
);

  //----------开关----------//
  logic [2:0] switch_reg;
  always_ff @(posedge lb.clk) begin
    switch_reg <= sw_raw;
  end


  //----------按键----------//
  logic [3:0] key_reg;
  always_ff @(posedge lb.clk) begin
    key_reg <= key_raw;
  end

  //----------读取----------//
  always_comb begin
    if (lb.addr[0] == 'd0) begin
      lb.rdata = 32'(~key_reg);
    end else begin
      lb.rdata = 32'(switch_reg);
    end
  end


endmodule
