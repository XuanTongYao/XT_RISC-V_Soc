// 停止等待状态机
// 输入pause(停止)跳转到WAIT等待状态
// 直到resume(恢复)信号输入
module StopAndWaitFSM #(
    // 是否重置到READY状态
    parameter bit RST_READY = 0
) (
    input clk,
    input rst,
    input pause,
    input resume,
    output logic ready
);
  typedef enum logic {
    WAIT  = '0,
    READY = '1
  } state_t;
  state_t state;

  always_ff @(posedge clk, posedge rst)
    if (rst) begin
      state <= RST_READY ? READY : WAIT;
    end else begin
      unique case (state)
        READY: if (pause) state <= WAIT;
        WAIT:  if (resume) state <= READY;
      endcase
    end

  assign ready = state;

endmodule
