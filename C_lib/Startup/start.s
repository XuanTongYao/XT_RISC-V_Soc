.section .init
.global _start
_start:
    li sp, 4096 # 初始化栈指针
    # 全局指针gp用于优化±2KB内全局变量的访问
    # 它的位置应该是全局区+2KB
    li gp, 4164 # 初始化全局指针 0x1044
    # 全局中断已在硬件初始化为0
    # csrsi mstatus, 0x8 # 启用全局中断
    # csrsi mstatus, 0x0 # 关闭全局中断
    # 初始化 中断向量
    lla t0,_exception
    ori t0, t0, 1
    csrw mtvec, t0
    # 初始化 mscratch保留16字空间(编译器在中断处理函数中似乎从来不使用mscratch？直接使用栈空间)
    li t0, 2048
    csrw mscratch, t0
    j main  # jump to main


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
.weak   ssoftware_IRQ_Handler
.weak   msoftware_IRQ_Handler
.weak   stimer_IRQ_Handler
.weak   mtimer_IRQ_Handler
.weak   sextern_IRQ_Handler
.weak   mextern_IRQ_Handler
# 自定义中断处理程序
.weak   UART_RX_IRQ_Handler
.weak   UART_TX_IRQ_Handler

.weak   I2C1_IRQ_Handler
.weak   I2C2_IRQ_Handler
.weak   SPI_IRQ_Handler
.weak   Timer_IRQ_Handler
.weak   WBC_UFM_IRQ_Handler

