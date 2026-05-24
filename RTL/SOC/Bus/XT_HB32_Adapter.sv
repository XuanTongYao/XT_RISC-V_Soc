// 32bit对齐总线适配器，更好的寻址性能与更低的资源占用
module XT_HB32_Adapter #(
    parameter int ADDR_WIDTH = 5,
    parameter int ID_WIDTH = 3,
    parameter int DEVICE_COUNT = 5
) (
    // 高速总线接口
    xt_hbus_if.port  hb,
    xt_hbus32_if.bus devices[DEVICE_COUNT]
);
  localparam int OFFSET_WIDTH = ADDR_WIDTH - ID_WIDTH;

  always_ff @(posedge hb.clk) begin
    if (hb.read_finish) begin
      hb.read_finish <= 0;
    end else if (hb.ren) begin
      hb.read_finish <= 1;
    end
  end
  assign hb.write_finish = 1;


  wire [ID_WIDTH-1:0] rid = hb.raddr[OFFSET_WIDTH+2+:ID_WIDTH];
  wire [ID_WIDTH-1:0] wid = hb.waddr[OFFSET_WIDTH+2+:ID_WIDTH];

  localparam int IDX_WIDTH = (DEVICE_COUNT == 1) ? 1 : $clog2(DEVICE_COUNT);
  logic [DEVICE_COUNT-1:0] id_sel[2];
  logic [IDX_WIDTH-1:0] id_sel_idx[2];
  SelectDecoder #(
      .UNIQUE_ID_MODE(1),
      .ID_WIDTH(ID_WIDTH),
      .ADDR_COUNT(2),
      .DEVICE_COUNT(DEVICE_COUNT)
  ) u_MMIO (
      .device_id('{rid, wid}),
      .sel(id_sel),
      .sel_idx(id_sel_idx)
  );
  wire [DEVICE_COUNT-1:0] raddr_sel = id_sel[0];
  wire [DEVICE_COUNT-1:0] waddr_sel = id_sel[1];
  wire [DEVICE_COUNT-1:0] rsel = hb.ren && !hb.read_finish ? raddr_sel : 0;
  wire [DEVICE_COUNT-1:0] wsel = hb.wen ? waddr_sel : 0;


  logic [31:0] device_data[DEVICE_COUNT];
  assign hb.rdata = device_data[id_sel_idx[0]];

  generate
    for (genvar i = 0; i < DEVICE_COUNT; ++i) begin : gen_device_link
      assign devices[i].clk   = hb.clk;
      assign devices[i].rst   = hb.rst;
      assign devices[i].raddr = hb.raddr[2+:OFFSET_WIDTH];
      assign devices[i].waddr = hb.waddr[2+:OFFSET_WIDTH];
      assign devices[i].wdata = hb.wdata;

      assign devices[i].ren   = rsel[i];
      assign devices[i].wen   = wsel[i];
      assign device_data[i]   = devices[i].rdata;
    end
  endgenerate

endmodule
