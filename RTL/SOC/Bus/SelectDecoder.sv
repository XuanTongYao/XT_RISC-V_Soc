// 片选信号解码器
// 通过输入的id(device_id)生成片选信号
// 使用唯一ID模式时(UNIQUE_ID_MODE=1):
//    BASE_ID无效，id直接作为索引把对应片选拉高
// 使用非唯一ID模式时(UNIQUE_ID_MODE=0):
//    BASE_ID是不包含0的逐个递增基准ID
//    id位于某个区间(左闭右开)时，把对应片选拉高
module SelectDecoder #(
    parameter bit UNIQUE_ID_MODE = 0,
    parameter int ID_WIDTH = 2,
    parameter int ADDR_COUNT = 2,
    parameter int DEVICE_COUNT = 4,
    localparam int IDX_WIDTH = (DEVICE_COUNT == 1) ? 1 : $clog2(DEVICE_COUNT),
    parameter bit [ID_WIDTH-1:0] BASE_ID[DEVICE_COUNT-1] = '{default: 'd0}
) (
    input [ID_WIDTH-1:0] device_id[ADDR_COUNT],
    output logic [DEVICE_COUNT-1:0] sel[ADDR_COUNT],
    output logic [IDX_WIDTH-1:0] sel_idx[ADDR_COUNT]
);

  generate
    if (DEVICE_COUNT == 1) begin : gen_direct
      always_comb begin
        for (int i = 0; i < ADDR_COUNT; ++i) begin
          sel_idx[i] = 0;
          sel[i] = 1'b1;
        end
      end
    end else if (UNIQUE_ID_MODE) begin : gen_unique_id
      for (genvar i = 0; i < ADDR_COUNT; ++i) begin : gen_id_to_sel
        always_comb begin
          sel_idx[i] = IDX_WIDTH'(device_id[i]);
          sel[i] = 0;
          if (device_id[i] < DEVICE_COUNT[ID_WIDTH-1:0]) begin
            sel[i][device_id[i]] = 1;
          end
        end
      end
    end else begin : gen_multi_id
      for (genvar i = 0; i < ADDR_COUNT; ++i) begin : gen_id_to_sel
        always_comb begin
          sel_idx[i] = 0;
          for (int j = 1; j < DEVICE_COUNT; ++j) begin
            if (device_id[i] >= BASE_ID[j-1]) begin
              sel_idx[i] = j[IDX_WIDTH-1:0];
            end
          end
        end
        always_comb begin
          sel[i] = 0;
          sel[i][sel_idx[i]] = 1'b1;
        end
      end
    end
  endgenerate

endmodule
