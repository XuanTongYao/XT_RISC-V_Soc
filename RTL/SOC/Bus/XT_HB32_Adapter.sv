// 32bit对齐总线适配器，更好的寻址性能与更低的资源占用
module XT_HB32_Adapter
  import Utils_Pkg::sel_t;
#(
    parameter int ADDR_WIDTH = 5,
    parameter int ID_WIDTH = 3,
    parameter int DEVICE_NUM = 5,
    parameter bit [ID_WIDTH-1:0] DEVICE_ID[DEVICE_NUM-1]
) (
    // 高速总线接口
    xt_hbus_device_if.port hb,
    xt_hbus32_if.bus       devices[DEVICE_NUM]
);
  localparam int OFFSET_WIDTH = ADDR_WIDTH - ID_WIDTH;

  always_ff @(posedge hb.clk) begin
    if (hb.read_finish) begin
      hb.read_finish <= 0;
    end else if (hb.sel.ren) begin
      hb.read_finish <= 1;
    end
  end
  assign hb.write_finish = 1;


  wire [ID_WIDTH-1:0] rid = hb.raddr[OFFSET_WIDTH+2+:ID_WIDTH];
  wire [ID_WIDTH-1:0] wid = hb.waddr[OFFSET_WIDTH+2+:ID_WIDTH];

  logic [DEVICE_NUM-1:0] id_sel[2];
  MMIO #(
      .ID_WIDTH(ID_WIDTH),
      .ADDR_NUM(2),
      .DEVICE_NUM(DEVICE_NUM),
      .BASE_ID(DEVICE_ID)
  ) u_MMIO (
      .device_id('{rid, wid}),
      .sel(id_sel)
  );
  wire [DEVICE_NUM-1:0] raddr_sel = id_sel[0];
  wire [DEVICE_NUM-1:0] waddr_sel = id_sel[1];
  wire [DEVICE_NUM-1:0] rsel = hb.sel.ren && !hb.read_finish ? raddr_sel : 0;
  wire [DEVICE_NUM-1:0] wsel = hb.sel.wen ? waddr_sel : 0;


  logic [31:0] device_data[DEVICE_NUM];
  always_comb begin
    hb.rdata = 0;
    for (int i = 0; i < DEVICE_NUM; ++i) begin
      if (raddr_sel[i]) begin
        hb.rdata = device_data[i];
        break;
      end
    end
  end

  generate
    for (genvar i = 0; i < DEVICE_NUM; ++i) begin : gen_device_link
      assign devices[i].clk = hb.clk;
      assign devices[i].rst = hb.rst;
      assign devices[i].raddr = hb.raddr[OFFSET_WIDTH+2-1:2];
      assign devices[i].waddr = hb.waddr[OFFSET_WIDTH+2-1:2];
      assign devices[i].wdata = hb.wdata;

      assign devices[i].sel.ren = rsel[i];
      assign devices[i].sel.wen = wsel[i];
      assign device_data[i] = devices[i].rdata;
    end
  endgenerate

endmodule
