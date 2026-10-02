/* 使用HIDDEN防止delete_IRQ_Handler全局符号被污染 */
/* 保证在查看反汇编时delete_IRQ_Handler符号名称不被替换，防止误判 */

/* 标准中断 */
PROVIDE_HIDDEN(ssoftware_IRQ_Handler   = delete_IRQ_Handler);
PROVIDE_HIDDEN(stimer_IRQ_Handler      = delete_IRQ_Handler);
PROVIDE_HIDDEN(sextern_IRQ_Handler     = delete_IRQ_Handler);
PROVIDE_HIDDEN(msoftware_IRQ_Handler   = delete_IRQ_Handler);
PROVIDE_HIDDEN(mtimer_IRQ_Handler      = delete_IRQ_Handler);
PROVIDE_HIDDEN(mextern_IRQ_Handler     = delete_IRQ_Handler);

/* 自定义中断 */
PROVIDE_HIDDEN(UART_RX_IRQ_Handler     = delete_IRQ_Handler);
PROVIDE_HIDDEN(UART_TX_IRQ_Handler     = delete_IRQ_Handler);
PROVIDE_HIDDEN(I2C1_IRQ_Handler        = delete_IRQ_Handler);
PROVIDE_HIDDEN(I2C2_IRQ_Handler        = delete_IRQ_Handler);
PROVIDE_HIDDEN(SPI_IRQ_Handler         = delete_IRQ_Handler);
PROVIDE_HIDDEN(Timer_IRQ_Handler       = delete_IRQ_Handler);
PROVIDE_HIDDEN(WBC_UFM_IRQ_Handler     = delete_IRQ_Handler);

/* 异常处理函数 */
PROVIDE_HIDDEN(Exception_Handler       = UnhandledFault);
