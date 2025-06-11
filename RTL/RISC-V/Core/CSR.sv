// 优化上电初值，节省了很多面积
module CSR
  import CSR_Typedefs::*;
(
    input clk,
    input rst_sync,
    input stall_n,
    input instruction_retire,

    input csr_r_en,
    input csr_w_en,
    input [11:0] csr_rwaddr,
    input [31:0] csr_wdata,
    output logic [31:0] csr_rdata,

    // 与异常/中断控制器连接
    output mstatus_t csr_mstatus,
    output mie_t csr_mie,
    output mip_t csr_mip,
    output logic [31:0] csr_mtvec,
    output logic [31:0] csr_mepc,

    input exception_occurred,
    input exception_returned,
    input [31:0] new_mepc,
    input [31:0] new_mcause,
    input [31:0] new_mtval,

    //中断源
    input mextern_int,
    input msoftware_int,
    input mtimer_int
);
  `define NORMAL 2'b00
  `define DEBUG 2'b01
  `define COUNTER 2'b10
  `define READONLY 2'b11
  wire [1:0] rw_mode = csr_rwaddr[11:10];
  `define USER 2'b00
  `define SUPERVISOR 2'b01
  `define HYPERVISOR 2'b10
  `define MACHINE 2'b11
  wire [1:0] privilege_level = csr_rwaddr[9:8];
  wire [7:0] short_addr = csr_rwaddr[7:0];
  wire atomic_rw_en = csr_w_en && stall_n && privilege_level == `MACHINE && rw_mode == `NORMAL;
  wire atomic_counter_rw_en = csr_w_en && stall_n && privilege_level == `MACHINE && rw_mode == `COUNTER;


  //----------机器模式CSR----------//
  // 信息寄存器
  // wire [31:0] mvendorid = 32'h31305458;  //  供应商 ID（不实现）
  // wire [31:0] marchid = 32'h31305458;  // 架构 ID（不实现）
  // wire [31:0] mimpid = 32'h31303030;  // 实现ID（不实现）
  wire [31:0] mhartid = 32'h0;  // 硬件线程ID
  wire [31:0] mconfigptr = 32'h0;  // 配置指针（假实现）

  // 自陷 配置
  mstatus_t mstatus = 0;  //状态寄存器
  // wire [31:0] misa = 32'h31305458;  //  ISA信息（不实现）
  // logic [31:0] medeleg;  //自陷转移寄存器（无S模式，不实现）
  // logic [31:0] mideleg;  //中断转移寄存器（无S模式，不实现）
  mie_t mie = 0;  //中断使能寄存器
  logic [31:0] mtvec;  //自陷处理函数基地址
  // logic [31:0] mcounteren;  //计数器使能（无U模式，不实现）
  // logic [31:0] mstatush;  //额外状态寄存器(RV32专属)（仅M模式，不实现）

  // 自陷处理
  logic [31:0] mscratch;  //自陷处理函数 Scratch 寄存器
  logic [31:0] mepc;  //异常程序地址
  logic [31:0] mcause;  //自陷原因
  wire [31:0] mtval = 0;  //自陷值（只读0实现）
  mip_t mip;  //挂起(待处理)的中断（只读）
  assign mip = {20'b0, mextern_int, 3'b0, mtimer_int, 3'b0, msoftware_int, 3'b0};
  // logic [31:0] mtinst;  //trap instruction (transformed)（无虚拟化，不实现）
  // logic [31:0] mtval2;  //bad guest physical address.（无虚拟化，不实现）


  // 连接机器模式控制器
  assign csr_mstatus = mstatus;
  assign csr_mie = mie;
  assign csr_mip = mip;
  assign csr_mtvec = mtvec;
  assign csr_mepc = mepc;


  // 配置（不实现）
  // 内存保护（不实现）
  // 定时器和计数器(事件计数器只读0)
  bit  [63:0] mcycle_all;  //运行周期数(只读实现)
  wire [31:0] mcycle = mcycle_all[31:0];  //运行周期数
  wire [31:0] mcycleh = mcycle_all[63:32];  // 运行周期数
  // wire [32:0] mcycle_plus1 = mcycle + 1'b1;
  // wire mcycle_carry = mcycle_plus1[32];

  wire [31:0] minstret = 0;  // 指令退役数(只读0实现)
  wire [31:0] minstreth = 0;  // 指令退役数(只读0实现)
  // wire [32:0] minstret_plus1 = minstret + instruction_retire;
  // wire minstret_carry = minstret_plus1[32];
  always_ff @(posedge clk) begin
    if (rst_sync) begin
      mcycle_all <= 0;
    end else begin
      mcycle_all <= mcycle_all + 1'b1;
      // mcycle  <= mcycle_plus1[31:0];
      // mcycleh <= mcycleh + mcycle_carry;
      // 这种写法可以优化资源？
      // if (atomic_counter_rw_en && short_addr == 8'h00) begin
      //   mcycle <= csr_wdata;
      // end else begin
      //   mcycle <= mcycle_plus1[31:0];
      // end
      // if (atomic_counter_rw_en && short_addr == 8'h80) begin
      //   mcycleh <= csr_wdata;
      // end else begin
      //   mcycleh <= mcycleh + mcycle_carry;
      // end
      // if (atomic_counter_rw_en && short_addr == 8'h02) begin
      //   minstret <= csr_wdata;
      // end else begin
      //   minstret <= minstret_plus1[31:0];
      // end
      // if (atomic_counter_rw_en && short_addr == 8'h82) begin
      //   minstreth <= csr_wdata;
      // end else begin
      //   minstreth <= minstreth + minstret_carry;
      // end
      // mcycle <= (atomic_counter_rw_en && short_addr == 8'h00) ? csr_wdata : mcycle_plus1[31:0];
      // mcycleh <= (atomic_counter_rw_en && short_addr == 8'h80) ? csr_wdata : mcycleh + mcycle_carry;
      // minstret <= (atomic_counter_rw_en && short_addr == 8'h02) ? csr_wdata : minstret_plus1[31:0];
      // minstreth <= (atomic_counter_rw_en && short_addr == 8'h82) ? csr_wdata : minstreth + minstret_carry;
    end
  end
  // 计数器配置(计数器永远计数，不实现)
  // 调试跟踪（不实现）
  // 调试模式（不实现）

  always_comb begin
    unique case (privilege_level)
      `USER, `SUPERVISOR, `HYPERVISOR: csr_rdata = 32'b0;
      `MACHINE: begin
        unique case (rw_mode)
          `READONLY: begin
            unique case (short_addr)
              8'h14:   csr_rdata = mhartid;
              8'h15:   csr_rdata = mconfigptr;
              default: csr_rdata = 32'b0;
            endcase
          end
          `COUNTER: begin
            unique case (short_addr)
              8'h00: csr_rdata = mcycle;
              8'h80: csr_rdata = mcycleh;

              8'h02:   csr_rdata = minstret;
              8'h82:   csr_rdata = minstreth;
              default: csr_rdata = 32'b0;
            endcase
          end
          default: begin
            unique case (short_addr)
              8'h00: csr_rdata = mstatus;
              8'h04: csr_rdata = mie;
              8'h05: csr_rdata = mtvec;

              8'h40:   csr_rdata = mscratch;
              8'h41:   csr_rdata = mepc;
              8'h42:   csr_rdata = mcause;
              8'h43:   csr_rdata = mtval;
              8'h44:   csr_rdata = mip;
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
      // mscratch <= 0;
      // mepc <= 0;
      // mcause <= 0;
      // mtval <= 0;
    end else begin
      if (atomic_rw_en) begin
        unique case (short_addr)
          8'h00: mstatus <= {24'b0, csr_wdata[7], 3'b0, csr_wdata[3], 3'b0};
          8'h04: mie <= {20'b0, csr_wdata[11], 3'b0, csr_wdata[7], 3'b0, csr_wdata[3], 3'b0};
          8'h05: mtvec <= csr_wdata;
          8'h40: mscratch <= csr_wdata;
          8'h41: mepc <= csr_wdata;  // (允许软件写入，通常用于ecall)
          // 8'h42: mcause <= csr_wdata;(禁止软件写入)
          // 8'h43: mtval <= csr_wdata;(禁止软件写入)
          // 8'h44: mip <= csr_wdata;(只读)
        endcase
      end else if (exception_occurred) begin
        mepc <= new_mepc;
        mcause <= new_mcause;
        // mtval <= new_mtval;
        mstatus <= {24'b0, mstatus.mie, 7'b0};
      end else if (exception_returned) begin
        mstatus <= {28'b0, mstatus.mpie, 3'b0};
      end
    end

  end

endmodule
