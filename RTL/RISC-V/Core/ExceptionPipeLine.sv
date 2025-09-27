module ExceptionPipeLine
  import Exception_Pkg::*;
(
    input clk,
    input rst_sync,
    input flush,
    input stall_n,

    //异常源
    input exception_t exception_if,
    input exception_t exception_id,
    // input exception_t exception_ex,

    // 提交点
    output exception_t exception_commit
);

  exception_t exception_if_id = 0;
  exception_t exception_id_ex = 0;
  always_ff @(posedge clk) begin
    if (rst_sync || flush) begin
      exception_if_id <= 0;
      exception_id_ex <= 0;
    end else if (stall_n) begin
      exception_if_id <= exception_if;
      if (exception_id.raise) begin
        exception_id_ex <= exception_id;
      end else begin
        exception_id_ex <= exception_if_id;
      end
    end
  end

  assign exception_commit = exception_id_ex;
  // assign exception_commit = exception_ex.raise ? exception_ex : exception_id_ex;

endmodule
