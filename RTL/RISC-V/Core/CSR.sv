// 优化上电初值，节省了很多面积
module CSR
  import CSR_Pkg::*;
  import CoreConfig::*;
#(
    parameter core_cfg_t CFG
) (
    input clk,
    input rst,
    input stall_n,
    input instruction_retire,

    // 读写接口
    csr_rw_if.csr rw,

    // 与异常/中断控制器连接
    output mstatus_t csr_mstatus,
    output mie_m_only_t csr_mie,
    output mip_m_only_t csr_mip,
    output mtvec_t csr_mtvec,
    output logic [CFG.PC_LEN-1:0] csr_mepc,

    input trap_occurred,
    input trap_returned,
    input [CFG.PC_LEN-1:0] new_mepc,
    input mcause_t new_mcause,
    // input [31:0] new_mtval,

    //中断源
    input mextern_int,
    input msoftware_int,
    input mtimer_int
);
  wire [7:0] short_addr = rw.addr.short_addr;
  wire atomic_rw_en = rw.wen && stall_n && rw.addr.privilege_level == MACHINE && rw.addr.mode == 2'b00;
  // wire atomic_counter_rw_en = csr_wen && stall_n && rw.addr.privilege_level == MACHINE && rw.addr.mode == 2'b10;


  //----------机器模式CSR----------//
  // 信息寄存器
  // wire [31:0] misa = {CFG.MXL, {CFG.XLEN - 28{1'b0}}, CFG.EXTENSION};  // ISA信息（不实现 只读0）
  // wire [31:0] mvendorid = 32'h31305458;  //  供应商 ID（不实现 只读0）
  // wire [31:0] marchid = 32'h31305458;  // 微架构 ID（不实现 只读0）
  // wire [31:0] mimpid = 32'h31303030;  // 实现版本ID（不实现 只读0）
  wire [31:0] mhartid = 32'h0;  // 硬件线程ID
  // wire [31:0] mconfigptr = 32'h0;  // 配置指针（配置数据不存在 只读0）

  // 自陷寄存器
  mstatus_t mstatus;  //状态寄存器
  mtvec_t mtvec;  //自陷处理函数基地址
  mie_m_only_t mie;  //中断使能寄存器
  mip_m_only_t mip;  //挂起(待处理)的中断（只读）
  assign mip = {mextern_int, mtimer_int, msoftware_int};

  logic [31:0] mscratch;  // 暂存寄存器
  logic [CFG.PC_LEN-1:0] mepc;  // 异常程序地址
  mcause_t mcause;  // 自陷原因
  // logic [31:0] mtval;  // 自陷额外信息（只读0实现）

  // 连接机器模式控制器
  assign csr_mstatus = mstatus;
  assign csr_mie = mie;
  assign csr_mip = mip;
  assign csr_mtvec = mtvec;
  assign csr_mepc = mepc;

  // 硬件性能监视(事件计数器只读0)
  bit  [63:0] mcycle_all;  //运行周期数(只读实现)
  wire [31:0] mcycle = mcycle_all[31:0];  //运行周期数
  wire [31:0] mcycleh = mcycle_all[63:32];  // 运行周期数
  // wire [31:0] minstret = 0;  // 指令退役数(只读0实现)
  // wire [31:0] minstreth = 0;  // 指令退役数(只读0实现)
  // wire [31:0] mhpmcounter_N = 0;  // 事件计数器(只读0实现)
  // wire [31:0] mhpmevent_N = 0;  // 事件选择器(只读0实现)
  // wire [31:0] mcountinhibit = 0;  // 计数器抑制(不实现)

  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      mcycle_all <= 0;
    end else begin
      mcycle_all <= mcycle_all + 1'b1;
    end
  end

  // 配置（不实现）
  // 内存保护（不实现）

  // 调试跟踪（不实现）
  // 调试模式（不实现）

  always_comb begin
    unique case (rw.addr.privilege_level)
      USER, SUPERVISOR, HYPERVISOR: rw.rdata = 32'b0;
      MACHINE: begin
        unique case (rw.addr.mode)
          READONLY: begin
            unique case (short_addr)
              8'h14:   rw.rdata = mhartid;
              // 8'h15:   csr_rdata = mconfigptr;
              default: rw.rdata = 32'b0;
            endcase
          end
          2'b10: begin
            unique case (short_addr)
              8'h00: rw.rdata = mcycle;
              8'h80: rw.rdata = mcycleh;

              // 8'h02:   csr_rdata = minstret;
              // 8'h82:   csr_rdata = minstreth;
              default: rw.rdata = 32'b0;
            endcase
          end
          default: begin
            unique case (short_addr)
              8'h00: rw.rdata = mstatus;
              8'h04: rw.rdata = PadMieMip(mie);
              8'h05: rw.rdata = mtvec;

              8'h40:   rw.rdata = mscratch;
              8'h41:   rw.rdata = CFG.XLEN'(PadPC(mepc, CFG.PC_ZEROS));
              8'h42:   rw.rdata = mcause;
              // 8'h43:   csr_rdata = mtval;
              8'h44:   rw.rdata = PadMieMip(mip);
              default: rw.rdata = 32'b0;
            endcase
          end
        endcase
      end
    endcase
  end


  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      mstatus <= 0;
      mie <= 0;
      mtvec <= 0;
    end else begin
      if (atomic_rw_en) begin
        unique case (short_addr)
          8'h00:   mstatus <= {24'b0, rw.wdata[7], 3'b0, rw.wdata[3], 3'b0};
          8'h04:   mie <= {rw.wdata[11], rw.wdata[7], rw.wdata[3]};
          8'h05:   mtvec <= rw.wdata;
          default: ;
        endcase
      end else if (trap_occurred) begin
        mstatus.mpie <= mstatus.mie;
        mstatus.mie  <= 0;
        // mstatus.mpp <= MACHINE;
      end else if (trap_returned) begin
        mstatus.mpie <= 1'b1;
        mstatus.mie  <= mstatus.mpie;
      end
    end
  end

  // 下面的寄存器初始值不影响硬件控制流
  always_ff @(posedge clk) begin
    if (atomic_rw_en) begin
      unique case (short_addr)
        8'h40:   mscratch <= rw.wdata;
        8'h41:   mepc <= rw.wdata[CFG.XLEN-1:CFG.PC_ZEROS];  // (允许软件写入，通常用于ecall)
        // 8'h42: mcause <= csr_wdata;(禁止软件写入)
        // 8'h43: mtval <= csr_wdata;(只读)
        // 8'h44: mip <= csr_wdata;(只读)
        default: ;
      endcase
    end else if (trap_occurred) begin
      mepc   <= new_mepc;
      mcause <= new_mcause;
      // mtval <= new_mtval;
    end
  end

endmodule
