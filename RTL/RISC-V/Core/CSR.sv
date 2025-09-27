// 优化上电初值，节省了很多面积
module CSR
  import CSR_Pkg::*;
  import CoreConfig::*;
(
    input clk,
    input rst_sync,
    input stall_n,
    input instruction_retire,

    input csr_ren,
    input csr_wen,
    input [11:0] csr_rwaddr,
    input [31:0] csr_wdata,
    output logic [31:0] csr_rdata,

    // 与异常/中断控制器连接
    output mstatus_t csr_mstatus,
    output mie_m_only_t csr_mie,
    output mip_m_only_t csr_mip,
    output mtvec_t csr_mtvec,
    output logic [PC_LEN-1:0] csr_mepc,

    input trap_occurred,
    input trap_returned,
    input [PC_LEN-1:0] new_mepc,
    input mcause_t new_mcause,
    // input [31:0] new_mtval,

    //中断源
    input mextern_int,
    input msoftware_int,
    input mtimer_int
);
  // `define NORMAL 2'b00
  // `define DEBUG 2'b01
  // `define COUNTER 2'b10
  `define READONLY 2'b11
  wire [1:0] rw_mode = csr_rwaddr[11:10];
  wire [1:0] privilege_level = csr_rwaddr[9:8];
  wire [7:0] short_addr = csr_rwaddr[7:0];
  wire atomic_rw_en = csr_wen && stall_n && privilege_level == MACHINE && rw_mode == 2'b00;
  // wire atomic_counter_rw_en = csr_wen && stall_n && privilege_level == MACHINE && rw_mode == 2'b10;


  //----------机器模式CSR----------//
  // 信息寄存器
  // wire [31:0] misa = {2'b01,4'b00,26'h100};  // ISA信息（不实现 只读0）
  // wire [31:0] mvendorid = 32'h31305458;  //  供应商 ID（不实现 只读0）
  // wire [31:0] marchid = 32'h31305458;  // 微架构 ID（不实现 只读0）
  // wire [31:0] mimpid = 32'h31303030;  // 实现版本ID（不实现 只读0）
  wire [31:0] mhartid = 32'h0;  // 硬件线程ID
  // wire [31:0] mconfigptr = 32'h0;  // 配置指针（配置数据不存在 只读0）

  // 自陷寄存器
  mstatus_t mstatus = 0;  //状态寄存器
  mtvec_t mtvec;  //自陷处理函数基地址
  mie_m_only_t mie = 0;  //中断使能寄存器
  mip_m_only_t mip;  //挂起(待处理)的中断（只读）
  assign mip = {mextern_int, mtimer_int, msoftware_int};

  logic [31:0] mscratch;  // 暂存寄存器
  logic [PC_LEN-1:0] mepc;  // 异常程序地址
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

  always_ff @(posedge clk) begin
    if (rst_sync) begin
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
    unique case (privilege_level)
      USER, SUPERVISOR, HYPERVISOR: csr_rdata = 32'b0;
      MACHINE: begin
        unique case (rw_mode)
          `READONLY: begin
            unique case (short_addr)
              8'h14:   csr_rdata = mhartid;
              // 8'h15:   csr_rdata = mconfigptr;
              default: csr_rdata = 32'b0;
            endcase
          end
          2'b10: begin
            unique case (short_addr)
              8'h00: csr_rdata = mcycle;
              8'h80: csr_rdata = mcycleh;

              // 8'h02:   csr_rdata = minstret;
              // 8'h82:   csr_rdata = minstreth;
              default: csr_rdata = 32'b0;
            endcase
          end
          default: begin
            unique case (short_addr)
              8'h00: csr_rdata = mstatus;
              8'h04: csr_rdata = PadMieMip(mie);
              8'h05: csr_rdata = mtvec;

              8'h40:   csr_rdata = mscratch;
              8'h41:   csr_rdata = PadPC(mepc);
              8'h42:   csr_rdata = mcause;
              // 8'h43:   csr_rdata = mtval;
              8'h44:   csr_rdata = PadMieMip(mip);
              default: csr_rdata = 32'b0;
            endcase
          end
        endcase
      end
    endcase
  end


  always_ff @(posedge clk) begin
    if (rst_sync) begin
      mstatus <= 0;
      mie <= 0;
      mtvec <= 0;
      // 下面的寄存器初始值不影响硬件控制流
    end else begin
      if (atomic_rw_en) begin
        unique case (short_addr)
          8'h00: mstatus <= {24'b0, csr_wdata[7], 3'b0, csr_wdata[3], 3'b0};
          8'h04: mie <= {csr_wdata[11], csr_wdata[7], csr_wdata[3]};
          8'h05: mtvec <= csr_wdata;
          8'h40: mscratch <= csr_wdata;
          8'h41: mepc <= csr_wdata[31:PC_ZEROS];  // (允许软件写入，通常用于ecall)
          // 8'h42: mcause <= csr_wdata;(禁止软件写入)
          // 8'h43: mtval <= csr_wdata;(只读)
          // 8'h44: mip <= csr_wdata;(只读)
        endcase
      end else if (trap_occurred) begin
        mepc <= new_mepc;
        mcause <= new_mcause;
        // mtval <= new_mtval;
        mstatus.mpie <= mstatus.mie;
        mstatus.mie <= 0;
        // mstatus.mpp <= MACHINE;
      end else if (trap_returned) begin
        mstatus.mpie <= 1'b1;
        mstatus.mie  <= mstatus.mpie;
      end
    end

  end

endmodule
