module ExceptionPipeLine
  import Exception_Pkg::*;
(
    input clk,
    input rst,
    input flush,
    input stall_n,

    //异常源
    exception_if.observer if_exception,
    exception_if.observer id_exception,
    // exception_if.observer ex_exception,

    // 提交点
    output exception_t exception_commit
);

  exception_t exception_if_id;
  exception_t exception_id_ex;
  always_ff @(posedge clk, posedge rst) begin
    if (rst || flush) begin
      exception_if_id <= 0;
      exception_id_ex <= 0;
    end else if (stall_n) begin
      exception_if_id <= '{raise: if_exception.raise, code: if_exception.code};
      if (id_exception.raise) begin
        exception_id_ex <= '{raise: id_exception.raise, code: id_exception.code};
      end else begin
        exception_id_ex <= exception_if_id;
      end
    end
  end

  assign exception_commit = exception_id_ex;
  // assign exception_commit = ex_exception.raise ? '{raise: 1'b1, code: ex_exception.code} : exception_id_ex;

endmodule
