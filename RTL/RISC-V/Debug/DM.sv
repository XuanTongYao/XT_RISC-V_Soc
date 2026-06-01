// Minimal RISC-V Debug Specification
// 最小 RISC-V 调试规范
// 不实现单独复位hart的hartreset
// 不实现身份验证
module DM
  import Debug_Pkg::*;
#(
    parameter bit [3:0] DATACOUNT = 4'd2
) (
    input dm_clk,
    input dm_rst_n,  // 因时钟发生故障而复位
    output logic dm_rst,
    dmi_if.dm dmi,

    output logic ndmreset  /* 复位除调试以外的所有逻辑 */,

    dm_hart_minimal_if.dm dm_hart,
    dm_register_if.dm access_register,
    memory_direct_if.master memory,
    xt_hbus_rsp_if.master memory_rsp
);
  localparam int unsigned SBADDRESS_COUNT = 1;
  localparam int unsigned SBDATA_COUNT = 1;

  // 复位控制
  logic con_reset_tff = 0;
  wire  con_reset_pulse;
  OncePulse u_OncePulse_dmcontrol_reset (
      .clk  (dm_clk),
      .ctrl (con_reset_tff),
      .pulse(con_reset_pulse)
  );

  wire rst_n;
  assign dm_rst = ~rst_n;
  SyncAsyncReset u_SyncAsyncReset (
      .clk    (dm_clk),
      .rst_i_n(dm_rst_n & ~con_reset_pulse),
      .rst_o_n(rst_n)
  );


  // 运行控制
  logic resumeack;

  // 必须的寄存器
  logic [31:0] data[DATACOUNT];

  dmcontrol_minimal_t dmcontrol;  // 精简版
  assign ndmreset = dmcontrol.ndmreset;
  dmstatus_minimal_t dmstatus;  // 只读
  assign dmstatus = '{
          anyhavereset: dm_hart.havereset,
          anyresumeack: resumeack,
          anyunavail: dm_hart.dm_state == UNAVAIL,
          anyrunning: dm_hart.dm_state == RUNNING,
          anyhalted: dm_hart.dm_state == HALTED
      };

  // cmderr在抽象命令结束后才改变
  abstractcs_variable_t abstractcs;  // 只有busy和cmderr是可用的
  command_t command;
  logic busy_err;

  logic [2:0] cmd_pending;
  wire command_access_register_t cmd_ar = command.control;
  assign access_register.aarsize = cmd_ar.aarsize;
  assign access_register.transfer = cmd_ar.transfer && cmd_pending[0];
  assign access_register.write = cmd_ar.write;
  assign access_register.regno = cmd_ar.regno;
  assign access_register.wdata = data[0];

  wire command_access_memory_t cmd_am = command.control;
  assign memory.read = !cmd_am.write && cmd_pending[2];
  assign memory.write = cmd_am.write && cmd_pending[2];
  assign memory.read_size = cmd_am.aamsize[1:0];
  assign memory.write_size = cmd_am.aamsize[1:0];
  assign memory.raddr = data[1];
  assign memory.waddr = data[1];
  assign memory.wdata = data[0];


  // sbcs_t              sbcs;
  // logic        [31:0] sbaddress  [SBADDRESS_COUNT];
  // logic        [31:0] sbdata     [    DATACOUNT];


  // 解析写入寄存器
  wire dmcontrol_t  req_dmcontrol = dmi.req_data;
  wire abstractcs_t req_abstractcs = dmi.req_data;
  wire command_t    req_command = dmi.req_data;

  assign dmi.rsp_valid = 1;
  wire dmi_req = dmi.req_valid && dmi.req_ready;
  always_ff @(posedge dm_clk) begin  // DMI读取逻辑+无需复位的逻辑
    if (dmi_req && dmcontrol.dmactive) begin
      if (dmi.req_op == 2'b01) begin  // 读取
        unique case (dmi.req_addr)
          DM_DATA_BASE: dmi.rsp_data <= data[0];
          DM_DATA_BASE + 'd1: dmi.rsp_data <= data[1];
          DM_DMSTATUS: dmi.rsp_data <= PadDmstatus(dmstatus, 4'd3);
          DM_ABSTRACTCS: dmi.rsp_data <= PadAbstractcs(abstractcs, 0, DATACOUNT);
          DM_COMMAND: dmi.rsp_data <= command;
          DM_SBCS: dmi.rsp_data <= UNSUPPORTED_SBCS;
          default: ;
        endcase
      end else if (dmi.req_op == 2'b10) begin  // 写入
        if (dmi.req_addr == DM_DATA_BASE) begin
          data[0] <= dmi.req_data;
        end else if (dmi.req_addr == (DM_DATA_BASE + 'd1)) begin
          data[1] <= dmi.req_data;
        end
      end
    end

    // dmcontrol.dmactive可以在非可用状态下读取和写入
    if (dmi_req && dmi.req_addr == DM_DMCONTROL) begin
      if (dmi.req_op == 2'b01) begin  // 读取
        dmi.rsp_data <= PadDmcontrol(dmcontrol);
      end else if (dmi.req_op == 2'b10 && !req_dmcontrol.dmactive) begin  // 写入
        con_reset_tff <= ~con_reset_tff;  // 设置复位并自动释放
      end
    end

    //----------抽象命令----------//
    if (cmd_pending[0] && access_register.completed) begin  // 等待完成
      if (!access_register.failed) begin
        data[0] <= access_register.rdata;
      end
    end else if (cmd_pending[2] && !memory_rsp.stall_req) begin
      data[0] <= memory.rdata;
    end
  end

  always_ff @(posedge dm_clk, posedge dm_rst) begin
    if (dm_rst) begin
      dmi.req_ready        <= 0;
      dmi.rsp_op           <= 2'b11;
      dmcontrol            <= 0;
      abstractcs           <= '{default: 0};
      command              <= 0;
      cmd_pending          <= 0;
      busy_err             <= 0;

      dm_hart.ackhavereset <= 0;
      dm_hart.haltreq      <= 0;
      dm_hart.resumereq    <= 0;
      resumeack            <= 0;
    end else begin
      if (dm_hart.dm_state == RUNNING && !resumeack) resumeack <= 1;
      if (dm_hart.resumereq) dm_hart.resumereq <= 0;  // 脉冲触发信号
      if (dm_hart.ackhavereset) dm_hart.ackhavereset <= 0;  // 脉冲触发信号

      if (!dmi.req_ready) dmi.req_ready <= 1;
      dmi.rsp_op <= 0;

      // DMI写入逻辑
      if (dmi_req && dmcontrol.dmactive && dmi.req_op == 2'b10) begin
        unique case (dmi.req_addr)
          DM_ABSTRACTCS: begin
            if (&req_abstractcs.cmderr) begin
              abstractcs.cmderr <= ERR_NONE;
            end
          end
          DM_COMMAND: begin
            if (abstractcs.cmderr == ERR_NONE) begin
              if (abstractcs.busy) begin
                busy_err <= 1;
              end else begin
                command <= dmi.req_data;
                abstractcs.busy <= 1;
              end
            end
          end
          default: ;
        endcase
      end

      // dmcontrol.dmactive可以在非可用状态下读取和写入
      if (dmi_req && dmi.req_addr == DM_DMCONTROL && dmi.req_op == 2'b10) begin
        if (dmcontrol.dmactive) begin
          dmcontrol.ndmreset <= req_dmcontrol.ndmreset;
          if (!abstractcs.busy) begin  // 不进行抽象命令才允许写入
            dm_hart.haltreq <= req_dmcontrol.haltreq;
            if (req_dmcontrol.resumereq && !dm_hart.haltreq) begin
              // haltreq时忽略对此的写入
              dm_hart.resumereq <= 1;
              resumeack <= 0;
            end
            if (req_dmcontrol.ackhavereset) dm_hart.ackhavereset <= 1;
          end
        end
        if (req_dmcontrol.dmactive) dmcontrol.dmactive <= 1;
      end

      //----------抽象命令----------//
      if (abstractcs.busy) begin
        if (cmd_pending[0]) begin  // 等待完成
          if (access_register.completed) begin
            if (busy_err) begin
              abstractcs.cmderr <= ERR_BUSY;
            end else if (access_register.failed) begin
              abstractcs.cmderr <= ERR_NOT_SUPPORTED;
            end
            cmd_pending <= 0;
            abstractcs.busy <= 0;
          end
        end else if (cmd_pending[2]) begin
          if (!memory_rsp.stall_req) begin
            if (busy_err) begin
              abstractcs.cmderr <= ERR_BUSY;
            end
            cmd_pending <= 0;
            abstractcs.busy <= 0;
          end
        end else begin  // 启动命令
          unique case (command.cmdtype)
            ACCESS_REGISTER: cmd_pending <= 3'b001;
            // QUICK_ACCESS: cmd_pending <= 3'b010;
            ACCESS_MEMORY:   cmd_pending <= 3'b100;
            default: begin
              abstractcs.busy   <= 0;
              abstractcs.cmderr <= ERR_NOT_SUPPORTED;
            end
          endcase
        end
      end
    end
  end



endmodule
