// DM使用系统时钟树上的时钟信号，如果PLL脱锁或时钟树故障，DM将不能工作
// 不过也确实，时钟树都故障了，还调试啥
// DM与DTM需要跨时钟域
module JtagDTM
  import Debug_Pkg::dtmcs_t;
#(
    // 7到32，最多只有32
    parameter int unsigned ABITS = 7,
    // 没有ManufId
    parameter bit [31:0] IDCODE_VALUE = 32'h0000_0001
) (
    input tck,
    input tms,
    input tdi,
    output logic tdo = 1'bz,


    input dm_clk,
    input dm_rst,
    dmi_if.dtm dmi
);


  //----------IR寄存器----------//
  // 寄存器地址/指令定义
  localparam bit [4:0] IR_IDCODE = 5'h01;
  // SAMPLE_PRELOAD采样所有顶层模块IO端口
  localparam bit [4:0] IR_SAMPLE_PRELOAD = 5'h02;
  // EXTEST采样所有顶层模块输入端口
  localparam bit [4:0] IR_EXTEST = 5'h03;
  localparam bit [4:0] IR_DTMCS = 5'h10;
  localparam bit [4:0] IR_DMI = 5'h11;
  localparam bit [4:0] IR_BYPASS = 5'h1f;
  // 边界扫描寄存器复用bypass(11.2.1 规则i)
  // SAMPLE_PRELOAD和EXTEST都使用bypass寄存器
  // update寄存器定义(默认选中bypass)
  typedef struct packed {
    logic dmi;
    logic dtmcs;
    logic idcode;
  } ir_update_t;
  logic [4:0] ir;
  ir_update_t ir_update = '{idcode: 1'b1, default: 1'b0};


  //----------DR寄存器----------//
  dtmcs_t dr_dtmcs_pi;

  typedef struct packed {
    logic [ABITS-1:0] address;
    logic [31:0] data;
    logic [1:0] op;
  } dmi_t;
  // localparam int unsigned DMI_BITS = ABITS + 34;

  // 边界扫描寄存器Boundary-scan复用bypass(11.2.1 规则i)
  logic dr_bypass;
  logic [31:0] dr_idcode;
  dtmcs_t dr_dtmcs;
  dmi_t dr_dmi, dr_dmi_pi;
  logic [ABITS-1:0] dr_dmi_addr;

  //----------TAP状态机----------//
  // 状态
  typedef enum bit [3:0] {
    TEST_LOGIC_RESET = 4'd0,
    RUN_TEST_IDLE    = 4'd1,
    SELECT_DR_SCAN   = 4'd2,
    CAPTURE_DR       = 4'd3,
    SHIFT_DR         = 4'd4,
    EXIT1_DR         = 4'd5,
    PAUSE_DR         = 4'd6,
    EXIT2_DR         = 4'd7,
    UPDATE_DR        = 4'd8,
    SELECT_IR_SCAN   = 4'd9,
    CAPTURE_IR       = 4'd10,
    SHIFT_IR         = 4'd11,
    EXIT1_IR         = 4'd12,
    PAUSE_IR         = 4'd13,
    EXIT2_IR         = 4'd14,
    UPDATE_IR        = 4'd15
  } tap_state_t;
  tap_state_t tap_state = TEST_LOGIC_RESET;

  always_ff @(posedge tck) begin
    unique case (tap_state)
      TEST_LOGIC_RESET: if (!tms) tap_state <= RUN_TEST_IDLE;
      RUN_TEST_IDLE: if (tms) tap_state <= SELECT_DR_SCAN;

      // DR状态
      SELECT_DR_SCAN: tap_state <= tms ? SELECT_IR_SCAN : CAPTURE_DR;
      CAPTURE_DR: begin
        if (ir_update.idcode) dr_idcode <= IDCODE_VALUE;
        else if (ir_update.dtmcs) dr_dtmcs <= dr_dtmcs_pi;
        else if (ir_update.dmi) dr_dmi <= dr_dmi_pi;
        else dr_bypass <= 0;

        tap_state <= tms ? EXIT1_DR : SHIFT_DR;
      end
      SHIFT_DR: begin
        if (ir_update.idcode) dr_idcode <= {tdi, dr_idcode[31:1]};
        else if (ir_update.dtmcs) dr_dtmcs <= {tdi, dr_dtmcs[31:1]};
        else if (ir_update.dmi) dr_dmi <= {tdi, dr_dmi[$size(dmi_t)-1:1]};
        else dr_bypass <= tdi;

        if (tms) tap_state <= EXIT1_DR;
      end
      EXIT1_DR:       tap_state <= tms ? UPDATE_DR : PAUSE_DR;
      PAUSE_DR:       if (tms) tap_state <= EXIT2_DR;
      EXIT2_DR:       tap_state <= tms ? UPDATE_DR : SHIFT_DR;
      UPDATE_DR: begin
        if (ir_update.dtmcs) begin
          // dmireset清除错误状态并重置errinfo 但我们不实现errinfo
          if (dr_dtmcs.dtmhardreset) begin
            // dr_dmi <= 0;  // 硬复位dtm
          end
        end else if (ir_update.dmi) begin
          unique case (dr_dmi.op)
            2'b01:   dr_dmi_addr <= dr_dmi.address;  // 读
            2'b10:   ;  // 写
            default: ;
          endcase
        end

        if (ir_update.dtmcs && dr_dtmcs.dtmhardreset) begin
          tap_state <= TEST_LOGIC_RESET;  // 硬复位dtm
        end else begin
          tap_state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
        end
      end

      // IR状态
      SELECT_IR_SCAN: tap_state <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
      CAPTURE_IR: begin
        ir <= 5'b00001;  // IR_IDCODE
        tap_state <= tms ? EXIT1_IR : SHIFT_IR;
      end
      SHIFT_IR: begin
        ir <= {tdi, ir[4:1]};  // 右移
        if (tms) tap_state <= EXIT1_IR;
      end
      EXIT1_IR: tap_state <= tms ? UPDATE_IR : PAUSE_IR;
      PAUSE_IR: if (tms) tap_state <= EXIT2_IR;
      EXIT2_IR: tap_state <= tms ? UPDATE_IR : SHIFT_IR;
      UPDATE_IR: tap_state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
      default: tap_state <= TEST_LOGIC_RESET;
    endcase
  end


  always_ff @(negedge tck) begin
    unique case (tap_state)
      SHIFT_DR: begin
        if (ir_update.idcode) tdo <= dr_idcode[0];
        else if (ir_update.dtmcs) tdo <= dr_dtmcs[0];
        else if (ir_update.dmi) tdo <= dr_dmi[0];
        else tdo <= dr_bypass;
      end
      SHIFT_IR: tdo <= ir[0];
      default:  tdo <= 1'bz;
    endcase
  end


  always_ff @(negedge tck) begin
    unique case (tap_state)
      TEST_LOGIC_RESET: ir_update <= '{idcode: 1'b1, default: 1'b0};
      UPDATE_IR: begin
        unique case (ir)
          IR_IDCODE: ir_update <= '{default: 0,idcode: 1'b1};
          IR_DTMCS:  ir_update <= '{default: 0,dtmcs: 1'b1};
          IR_DMI:    ir_update <= '{default: 0,dmi: 1'b1 };
          default:   ir_update <= '{default: 0};
        endcase
      end
      default:          ;
    endcase
  end



  //----------与DM的交互----------//
  // 使用CDC跨时钟域，简化REQ_VALID和RSP_VALID
  assign dmi.rsp_ready = 1;

  logic dm_ready_sync, dm_ready;
  always_ff @(posedge tck) begin
    dm_ready_sync <= dmi.req_ready;
    dm_ready <= dm_ready_sync;
  end

  logic send_dm = 0;
  always_ff @(posedge tck) begin
    // tms为1时会从EXIT1_DR或EXIT2_DR切换到UPDATE_DR，提前把send_dm设1
    if (send_dm) begin
      send_dm <= 0;
    end else if ((tap_state == EXIT1_DR || tap_state == EXIT2_DR) && tms && ir_update.dmi &&
                 (dr_dmi.op == 2'b01 || dr_dmi.op == 2'b10)) begin
      send_dm <= 1;
    end
  end

  wire dm_send_ready;
  wire dm_ack;
  CDC_MCP_Formulation #(
      .CDC_DATA_WIDTH($size(dmi_t))
  ) u_CDC_MCP_Formulation (
      .clk_send  (tck),
      .rst_send  (dm_rst),
      .send      (send_dm),
      .send_ready(dm_send_ready),
      .ack       (dm_ack),

      .clk_receive  (dm_clk),
      .rst_receive  (dm_rst),
      .receive      (dmi.rsp_valid),
      .receive_ready(dmi.req_valid),
      .data_in      (dr_dmi),
      .data_out     ({dmi.req_addr, dmi.req_data, dmi.req_op})
  );

  logic [31:0] dm_data = 0;
  logic [1:0] dm_op = 0, dm_op_bypass;
  always_ff @(posedge tck) begin
    if (dm_ack) begin
      dm_data <= dmi.rsp_data;
      dm_op   <= dmi.rsp_op;
    end
  end
  assign dm_op_bypass = (dm_ready && dm_send_ready) ? dm_op : 2'b11;
  assign dr_dmi_pi = '{address: dr_dmi_addr, data: dm_data, op: dm_op_bypass};
  assign dr_dtmcs_pi = '{default: 0, dmistat: dm_op_bypass, idle: 3'd2, abits: 6'(ABITS), version: 4'd1};

endmodule

