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
    // input instruction_retire,
    input debug_override_csr,

    // 读写接口
    csr_rw_if.csr rw,
    csr_rw_if.csr debug_rw_csr,

    // 自陷控制接口
    trap_if.csr trap,
    // input [31:0] new_mtval,

    // 中断源
    int_source_if.hart mint,

    // 调试控制器
    debug_if.csr debug
);
  // 调试器覆盖
  logic ren, wen;
  csr_addr_t rwaddr;
  logic [CFG.XLEN-1:0] wdata;
  always_comb begin
    if (debug_override_csr) begin
      ren = debug_rw_csr.ren;
      wen = debug_rw_csr.wen;
      rwaddr = debug_rw_csr.addr;
      wdata = debug_rw_csr.wdata;
    end else begin
      ren = rw.ren;
      wen = rw.wen;
      rwaddr = rw.addr;
      wdata = rw.wdata;
    end
  end

  logic [CFG.XLEN-1:0] rdata;
  assign rw.rdata = rdata;
  assign debug_rw_csr.rdata = rdata;


  wire [7:0] short_addr = rwaddr.short_addr;
  wire atomic_rw_en = wen && (stall_n || debug.halted) && rwaddr.privilege_level == MACHINE;
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
  assign mip = {mint.mextern_int, mint.mtimer_int, mint.msoftware_int};

  logic [31:0] mscratch;  // 暂存寄存器
  logic [CFG.PC_LEN-1:0] mepc;  // 异常程序地址
  mcause_t mcause;  // 自陷原因
  // logic [31:0] mtval;  // 自陷额外信息（只读0实现）

  // 连接自陷控制接口
  assign trap.mstatus = mstatus;
  assign trap.mie = mie;
  assign trap.mip = mip;
  assign trap.mtvec = mtvec;
  assign trap.mepc = mepc;

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

  // 调试触发器模块 Sdtrig扩展（不实现）

  // Sdext扩展(调试模式)
  dcsr_only_sdext_t dcsr;
  logic [CFG.PC_LEN-1:0] dpc;
  assign debug.dcsr = dcsr;
  assign debug.dpc  = dpc;

  always_comb begin
    rdata = 0;
    unique case (rwaddr.privilege_level)
      USER, SUPERVISOR, HYPERVISOR: ;
      MACHINE: begin
        unique case (rwaddr.mode)
          READONLY: begin
            unique case (short_addr)
              8'h14:   rdata = mhartid;
              // 8'h15:   csr_rdata = mconfigptr;
              default: rdata = 32'b0;
            endcase
          end
          2'b01:
          if (debug.halted) begin
            unique case (short_addr)
              8'hb0:   rdata = PadDcsr(dcsr);
              8'hb1:   rdata = CFG.XLEN'(PadPC(dpc, CFG.PC_ZEROS));
              default: ;
            endcase
          end
          2'b10: begin
            unique case (short_addr)
              8'h00: rdata = mcycle;
              8'h80: rdata = mcycleh;

              // 8'h02:   csr_rdata = minstret;
              // 8'h82:   csr_rdata = minstreth;
              default: ;
            endcase
          end
          2'b00: begin
            unique case (short_addr)
              8'h00: rdata = mstatus;
              8'h04: rdata = PadMieMip(mie);
              8'h05: rdata = mtvec;

              8'h40:   rdata = mscratch;
              8'h41:   rdata = CFG.XLEN'(PadPC(mepc, CFG.PC_ZEROS));
              8'h42:   rdata = mcause;
              // 8'h43:   csr_rdata = mtval;
              8'h44:   rdata = PadMieMip(mip);
              default: ;
            endcase
          end
        endcase
      end
    endcase
  end


  wire dcsr_t write_dcsr = wdata;
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      mstatus <= 0;
      mie <= 0;
      mtvec <= 0;
      dcsr <= 0;
    end else begin
      if (atomic_rw_en && rwaddr.mode == 2'b00) begin
        unique case (short_addr)
          8'h00:   mstatus <= {24'b0, wdata[7], 3'b0, wdata[3], 3'b0};
          8'h04:   mie <= {wdata[11], wdata[7], wdata[3]};
          8'h05:   mtvec <= wdata;
          default: ;
        endcase
      end else if (debug.halted) begin
        if (atomic_rw_en && rwaddr.mode == 2'b01 && short_addr == 8'hb0) begin
          dcsr.ebreakm <= write_dcsr.ebreakm;
          dcsr.step <= write_dcsr.step;
        end
      end else if (debug.halt) begin
        dcsr.cause <= debug.new_cause;
      end else if (trap.occurred) begin
        mstatus.mpie <= mstatus.mie;
        mstatus.mie  <= 0;
        // mstatus.mpp <= MACHINE;
      end else if (trap.returned) begin
        mstatus.mpie <= 1'b1;
        mstatus.mie  <= mstatus.mpie;
      end
    end
  end

  // 下面的寄存器初始值不影响硬件控制流
  always_ff @(posedge clk) begin
    if (atomic_rw_en && rwaddr.mode == 2'b00) begin
      unique case (short_addr)
        8'h40:   mscratch <= wdata;
        8'h41:   mepc <= wdata[CFG.XLEN-1:CFG.PC_ZEROS];  // (允许软件写入，通常用于ecall)
        // 8'h42: mcause <= csr_wdata;(禁止软件写入)
        // 8'h43: mtval <= csr_wdata;(只读)
        // 8'h44: mip <= csr_wdata;(只读)
        default: ;
      endcase
    end else if (debug.halted) begin
      if (atomic_rw_en && rwaddr.mode == 2'b01 && short_addr == 8'hb1) begin
        dpc <= wdata[CFG.XLEN-1:CFG.PC_ZEROS];
      end
    end else if (debug.halt) begin
      dpc <= debug.new_dpc;
    end else if (trap.occurred) begin
      mepc   <= trap.new_mepc;
      mcause <= trap.new_mcause;
      // mtval <= new_mtval;
    end
  end

endmodule
