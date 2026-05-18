// 与系统强相关的外设
// 比如内存映射CSR，外部中断控制器，自举启动和DMA等
module XT_HB32_Adapter
  import Utils_Pkg::sel_t;
(
    input rst,
    // 高速总线接口
    xt_hbus_device_if.port hb,
    xt_hbus32_if.bus hb32
);
  localparam int ID_WIDTH = hb32.ID_WIDTH;
  localparam int OFFSET_WIDTH = hb32.ADDR_WIDTH - ID_WIDTH;
  localparam int DEVICE_NUM = hb32.DEVICE_NUM;

  assign hb32.clk   = hb.clk;
  assign hb32.raddr = hb.raddr[OFFSET_WIDTH+2-1:2];
  assign hb32.waddr = hb.waddr[OFFSET_WIDTH+2-1:2];
  assign hb32.wdata = hb.wdata;

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

  localparam bit [ID_WIDTH-1:0] DEVICE_ID[DEVICE_NUM-1] = '{3'd1, 3'd2, 3'd3, 3'd4};

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
  logic [DEVICE_NUM-1:0] raddr_sel = id_sel[0];
  logic [DEVICE_NUM-1:0] waddr_sel = id_sel[1];

  always_comb begin
    hb.rdata = 0;
    for (int i = 0; i < DEVICE_NUM; ++i) begin
      if (raddr_sel[i]) begin
        hb.rdata = hb32.device_data[i];
        break;
      end
    end
  end

  wire [DEVICE_NUM-1:0] rsel = hb.sel.ren && !hb.read_finish ? raddr_sel : 0;
  wire [DEVICE_NUM-1:0] wsel = hb.sel.wen ? waddr_sel : 0;
  generate
    for (genvar i = 0; i < DEVICE_NUM; ++i) begin : gen_sel
      assign hb32.device_sel[i].ren = rsel[i];
      assign hb32.device_sel[i].wen = wsel[i];
    end
  endgenerate

endmodule
