module XT_HB_Domain
  import XT_BUS::*;
#(
    parameter int SLAVE_NUM = 4
) (
    input hb_clk,
    input hb_slave_t xt_hb,
    input sel_t sel,
    input [31:0] hb_data_in[SLAVE_NUM],

    output logic read_finish,
    output logic write_finish,
    output logic [31:0] rdata,
    output sel_t hb_sel[SLAVE_NUM]
);
  always_ff @(posedge hb_clk) begin
    if (read_finish) begin
      read_finish <= 0;
    end else if (sel.ren) begin
      read_finish <= 1;
    end
  end
  assign write_finish = 1;


  `define AW `ADDR_WIDTH
  wire [7:0] raddr = xt_hb.raddr[7:0];
  wire [7:0] waddr = xt_hb.waddr[7:0];


  //----------从设备数据选择----------//
  logic [SLAVE_NUM-1:0] slave_wsel;
  always_comb begin
    slave_wsel = 0;
    unique case (xt_hb.waddr)
      // DEBUG
      `AW'd0, `AW'd1, `AW'd2, `AW'd3:     slave_wsel[0] = 1;
      // EINT_CTRL(对齐)
      `AW'd4, `AW'd8:                     slave_wsel[1] = 1;
      // SYSTEM_TIMER(对齐)
      `AW'd12, `AW'd16, `AW'd20, `AW'd24: slave_wsel[2] = 1;
      // UART
      `AW'd28, `AW'd29, `AW'd30, `AW'd31: slave_wsel[3] = 1;
      default:                            slave_wsel = 0;
    endcase
  end

  logic [SLAVE_NUM-1:0] slave_rsel;
  always_comb begin
    slave_rsel = 0;
    rdata = 0;
    unique case (xt_hb.raddr)
      // DEBUG
      `AW'd0, `AW'd1, `AW'd2, `AW'd3: begin
        rdata = hb_data_in[0];
        slave_rsel[0] = 1;
      end
      // EINT_CTRL(对齐)
      `AW'd4, `AW'd8: begin
        rdata = hb_data_in[1];
        slave_rsel[1] = 1;
      end
      // SYSTEM_TIMER(对齐)
      `AW'd12, `AW'd16, `AW'd20, `AW'd24: begin
        rdata = hb_data_in[2];
        slave_rsel[2] = 1;
      end
      // UART
      `AW'd28, `AW'd29, `AW'd30, `AW'd31: begin
        rdata = hb_data_in[3];
        slave_rsel[3] = 1;
      end
      default: rdata = 0;
    endcase
  end

  wire [SLAVE_NUM-1:0] out_slave_rsel = sel.ren && !read_finish ? slave_rsel : 0;
  wire [SLAVE_NUM-1:0] out_slave_wsel = sel.wen ? slave_wsel : 0;
  generate
    for (genvar i = 0; i < SLAVE_NUM; ++i) begin : gen_slaves_sel
      assign hb_sel[i].ren = out_slave_rsel[i];
      assign hb_sel[i].wen = out_slave_wsel[i];
    end
  endgenerate


endmodule
