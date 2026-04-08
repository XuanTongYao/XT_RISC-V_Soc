/* 标准中断 */
PROVIDE_HIDDEN(ssoftware_IRQ_Handler   = delete_IRQ_handler);
PROVIDE_HIDDEN(stimer_IRQ_Handler      = delete_IRQ_handler);
PROVIDE_HIDDEN(sextern_IRQ_Handler     = delete_IRQ_handler);
PROVIDE_HIDDEN(msoftware_IRQ_Handler   = delete_IRQ_handler);
PROVIDE_HIDDEN(mtimer_IRQ_Handler      = delete_IRQ_handler);
PROVIDE_HIDDEN(mextern_IRQ_Handler     = delete_IRQ_handler);

/* 自定义中断 */
PROVIDE_HIDDEN(UART_RX_IRQ_Handler     = delete_IRQ_handler);
PROVIDE_HIDDEN(UART_TX_IRQ_Handler     = delete_IRQ_handler);
PROVIDE_HIDDEN(I2C1_IRQ_Handler        = delete_IRQ_handler);
PROVIDE_HIDDEN(I2C2_IRQ_Handler        = delete_IRQ_handler);
PROVIDE_HIDDEN(SPI_IRQ_Handler         = delete_IRQ_handler);
PROVIDE_HIDDEN(Timer_IRQ_Handler       = delete_IRQ_handler);
PROVIDE_HIDDEN(WBC_UFM_IRQ_Handler     = delete_IRQ_handler);

/* 异常处理函数 */
/* 极简的内核只有以下这些异常 */
PROVIDE_HIDDEN(Illegal_inst_ErrorHandler           = UnhandledFault);
PROVIDE_HIDDEN(Load_addr_misaligned_ErrorHandler   = UnhandledFault);
PROVIDE_HIDDEN(Store_addr_misaligned_ErrorHandler  = UnhandledFault);
PROVIDE_HIDDEN(Ecall_ErrorHandler                  = UnhandledFault);
