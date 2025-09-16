// @Deprecated
// 已弃用
// 将地址按照分割点线性映射并输出独热码片选
// 从0开始切分区域，下方区域不包括分割点的地址
// 用比较器的方式效率太低了
module AddressMapping #(
    parameter int ADDR_WIDTH = 16,
    parameter int MAPPED_ADDR_WIDTH = 12,
    parameter int ADDR_NUM = 2,
    parameter int SLICE_NUM = 4,
    parameter int SLICE[SLICE_NUM-1]
) (
    input [ADDR_WIDTH-1:0] addr[ADDR_NUM],
    output logic [MAPPED_ADDR_WIDTH-1:0] mapped_addr[ADDR_NUM],
    output logic [SLICE_NUM-1:0] sel[ADDR_NUM]
);

  generate
    if (SLICE_NUM == 1) begin : gen_direct
      assign mapped_addr = addr[MAPPED_ADDR_WIDTH-1:0];
      always_comb begin
        for (int i = 0; i < ADDR_NUM; ++i) begin
          sel[i] = 1'b1;
        end
      end
    end else begin : gen_mapping
      for (genvar i = 0; i < ADDR_NUM; ++i) begin : gen_multi_addr_mapping
        logic [ADDR_WIDTH-1:0] SLICE_ADDR_START;
        always_comb begin
          sel[i] = 0;
          sel[i][0] = 1;
          SLICE_ADDR_START = 0;
          for (int j = 1; j < SLICE_NUM; ++j) begin
            if (addr[i] >= SLICE[j-1][ADDR_WIDTH-1:0]) begin
              SLICE_ADDR_START = SLICE[j-1][ADDR_WIDTH-1:0];
              sel[i] = 0;
              sel[i][j] = 1;
            end
          end
          mapped_addr[i] = addr[i] - SLICE_ADDR_START;
        end
      end
    end
  endgenerate

endmodule
