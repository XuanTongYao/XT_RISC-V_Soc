.section .init
.global _start
_start:
    .option push
    .option norelax
1:  auipc gp, %pcrel_hi(__global_pointer$)
    addi gp, gp, %pcrel_lo(1b)
    .option pop
    lla sp, _sstack # 初始化栈指针
    # 初始化 中断向量
    lla a0, __TRAP_VECTOR__
    ori a0, a0, 1
    csrw mtvec, a0
    # 清空 未初始化段
    lla a0, __BSS_START__
	lla a1, __BSS_END__
	bgeu a0, a1, 2f
1:
	sw x0, (a0)
	addi a0, a0, 4
	bltu a0, a1, 1b
2:
    call main  # jump to main


.section .trap.vector
# 异常/中断向量表
_exception:
    j Exception_Handler
_software_int:
    j ssoftware_IRQ_Handler # 未实现S模式
    mret
    j msoftware_IRQ_Handler
    mret
_timer_int:
    j stimer_IRQ_Handler # 未实现S模式
    mret
    j mtimer_IRQ_Handler
    mret
_extern_int: # 外部中断由外部中断控制器重定向到自定义中断
    j sextern_IRQ_Handler # 未实现S模式
    mret
    j mextern_IRQ_Handler # 由硬件重定向
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


# 弃置的自陷处理函数
.section .trap.delete_handler
.global delete_IRQ_handler
# 标准中断
ssoftware_IRQ_Handler:
stimer_IRQ_Handler:
sextern_IRQ_Handler:
msoftware_IRQ_Handler:
mtimer_IRQ_Handler:
mextern_IRQ_Handler:
# 自定义中断
UART_RX_IRQ_Handler:
UART_TX_IRQ_Handler:
I2C1_IRQ_Handler:
I2C2_IRQ_Handler:
SPI_IRQ_Handler:
Timer_IRQ_Handler:
WBC_UFM_IRQ_Handler:
delete_IRQ_handler:
    mret


.section .trap.error_handler

# 极简的内核只有以下这些异常
.weak   Illegal_inst_ErrorHandler # 2
.weak   Load_addr_misaligned_ErrorHandler # 4
.weak   Store_addr_misaligned_ErrorHandler # 6
.weak   Ecall_ErrorHandler # 11

# 致命错误死循环
.global UnhandledFault
Illegal_inst_ErrorHandler:
Load_addr_misaligned_ErrorHandler:
Store_addr_misaligned_ErrorHandler:
Ecall_ErrorHandler:
UnhandledFault:
    j UnhandledFault

.global _Exception_Exit
Exception_Handler:
    # 保存"调用者保存寄存器"
    addi    sp,sp,-48
    sw ra, 44(sp)
    sw a0, 40(sp)
    sw a1, 36(sp)
    sw a2, 32(sp)
    sw a3, 28(sp)
    sw a4, 24(sp)
    sw a5, 20(sp)
    sw a6, 16(sp)
    sw a7, 12(sp)
    sw t0, 8(sp)
    sw t1, 4(sp)

    lla ra, _Exception_Exit # 返回地址重定向
    csrr t1, mcause # 读取异常类型
    # 判断异常类型
    li t0, 11
    beq t0, t1, 11f
    li t0, 6 
    beq t0, t1, 6f
    li t0, 4 
    beq t0, t1, 4f
    li t0, 2 
    beq t0, t1, 2f
    j UnhandledFault
2:
    j Illegal_inst_ErrorHandler
4:
    j Load_addr_misaligned_ErrorHandler
6:
    j Store_addr_misaligned_ErrorHandler
11:
    j Ecall_ErrorHandler

_Exception_Exit:
    lw ra, 44(sp)
    lw a0, 40(sp)
    lw a1, 36(sp)
    lw a2, 32(sp)
    lw a3, 28(sp)
    lw a4, 24(sp)
    lw a5, 20(sp)
    lw a6, 16(sp)
    lw a7, 12(sp)
    lw t0, 8(sp)
    lw t1, 4(sp)
    addi    sp,sp,48
    mret


