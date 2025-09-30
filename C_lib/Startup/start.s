.section .init
.global _start
_start:
    .option push
    .option norelax
1:  la sp, _sstack # 初始化栈指针
    auipc gp, %pcrel_hi(__global_pointer$)
    addi gp, gp, %pcrel_lo(1b)
    csrwi mscratch,0
    .option pop
    csrci mstatus, 0x8 # 关闭全局中断
    # 初始化 中断向量
    lla t0,_exception
    ori t0, t0, 1
    csrw mtvec, t0
    j main  # jump to main


.section .trap.vector
# 异常/中断向量表
_exception:
    j Exception_Handler
_software_int:
    j ssoftware_IRQ_Handler
    mret
    j msoftware_IRQ_Handler
    mret
_timer_int:
    j stimer_IRQ_Handler
    mret
    j mtimer_IRQ_Handler
    mret
_extern_int: # 外部中断由外部中断控制器重定向到自定义中断
    j sextern_IRQ_Handler # 已经无效
    mret
    j mextern_IRQ_Handler # 已经无效
    mret
    nop
    nop
    nop
# 自定义中断中断号16开始，对应外部中断的0号中断
_custom_int:
    j UART_RX_IRQ_Handler
    mret # 保留
    mret
    mret
    mret
    mret
    mret
    mret
    j I2C1_IRQ_Handler
    j I2C2_IRQ_Handler
    j SPI_IRQ_Handler
    j Timer_IRQ_Handler
    j WBC_UFM_IRQ_Handler


.section .trap.delete_handler
ssoftware_IRQ_Handler:
stimer_IRQ_Handler:
sextern_IRQ_Handler:
mextern_IRQ_Handler:
delete_IRQ_handler:
    mret


.section .trap.error_handler
# 致命错误死循环
UnhandledFault:
    j UnhandledFault

# 极简的内核只有以下这些异常
.weak   Illegal_inst_ErrorHandler # 2
.weak   Load_addr_misaligned_ErrorHandler # 4
.weak   Store_addr_misaligned_ErrorHandler # 6
.weak   Ecall_ErrorHandler # 11

Exception_Handler:
    addi    sp,sp,-16
    sw t1, 12(sp)
    # 判断异常类型
    csrr t1, mcause
    addi t1, t1, -11; # M环境调用异常号
    bnez t1, UnhandledFault;
    lw t1, 12(sp)
    addi    sp,sp,16
    j Ecall_ErrorHandler
    mret


.section    .text
# .weak   ssoftware_IRQ_Handler
# .weak   stimer_IRQ_Handler
# .weak   sextern_IRQ_Handler
.weak   msoftware_IRQ_Handler
.weak   mtimer_IRQ_Handler
# .weak   mextern_IRQ_Handler
# 自定义中断处理程序
.weak   UART_RX_IRQ_Handler
.weak   UART_TX_IRQ_Handler

.weak   I2C1_IRQ_Handler
.weak   I2C2_IRQ_Handler
.weak   SPI_IRQ_Handler
.weak   Timer_IRQ_Handler
.weak   WBC_UFM_IRQ_Handler

