/* 我不知道这里为什么使用PROVIDE_HIDDEN而不是PROVIDE */
/* 初次提交就已经是修正后可运行的版本 */
/* 我现在也回想不到之前使用PROVIDE发生了什么问题 */

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
PROVIDE_HIDDEN(Exception_Handler       = UnhandledFault);
