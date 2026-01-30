// @Deprecated
// 已弃用
module ClockDomainCrossing #(
    parameter int CDC_DFF_NUM = 8
) (
    input fast_clk,
    input data_enable,
    input ack,

    input [CDC_DFF_NUM-1:0] data_in,
    output logic [CDC_DFF_NUM-1:0] data_out,
    output logic data_valid,
    output logic waiting_slow_domain
);

  wire ack_pulse;
  OncePulse #(
      .TRIGGER(2'b11)  // 双边沿触发
  ) u_OncePulse (
      .clk  (fast_clk),
      .ctrl (ack),
      .pulse(ack_pulse)
  );

  logic locked = 0;
  always_ff @(posedge fast_clk) begin
    if (ack_pulse) begin
      data_out <= 0;
    end else if (data_enable && !locked) begin
      data_out <= data_in;
    end
  end

  logic stable = 0;
  always_ff @(posedge fast_clk) begin
    if (ack_pulse) begin
      locked <= 0;
      stable <= 0;
    end else if (data_enable) begin
      locked <= 1;
      stable <= locked;
    end
  end

  assign waiting_slow_domain = data_enable && !ack_pulse;
  assign data_valid = stable && !ack_pulse;

endmodule
