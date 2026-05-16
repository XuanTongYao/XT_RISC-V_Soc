// 先实现一个从0开始的
module MMIO #(
    parameter int ID_WIDTH = 2,
    parameter int ADDR_NUM = 2,
    parameter int DEVICE_NUM = 4,
    parameter bit [ID_WIDTH-1:0] BASE_ID[DEVICE_NUM-1]
) (
    input [ID_WIDTH-1:0] device_id[ADDR_NUM],
    output logic [DEVICE_NUM-1:0] sel[ADDR_NUM]
);

  generate
    if (DEVICE_NUM == 1) begin : gen_direct
      always_comb begin
        for (int i = 0; i < ADDR_NUM; ++i) begin
          sel[i] = 1'b1;
        end
      end
    end else begin : gen_mapping
      for (genvar i = 0; i < ADDR_NUM; ++i) begin : gen_multi_addr_mapping
        always_comb begin
          sel[i] = 0;
          sel[i][0] = 1;
          for (int j = 1; j < DEVICE_NUM; ++j) begin
            if (device_id[i] >= BASE_ID[j-1]) begin
              sel[i] = 0;
              sel[i][j] = 1;
            end
          end
        end
      end
    end
  endgenerate

endmodule
