/* 使用HIDDEN防止DefaultHandler全局符号被污染 */
/* 保证在查看反汇编时DefaultHandler符号名称不被替换，防止误判 */
PROVIDE_HIDDEN(DefaultHandler = AbortHalt);

/* 标准中断 */
PROVIDE_HIDDEN(ssoftware_IRQ_Handler   = DefaultHandler);
PROVIDE_HIDDEN(stimer_IRQ_Handler      = DefaultHandler);
PROVIDE_HIDDEN(sextern_IRQ_Handler     = DefaultHandler);
PROVIDE_HIDDEN(msoftware_IRQ_Handler   = DefaultHandler);
PROVIDE_HIDDEN(mtimer_IRQ_Handler      = DefaultHandler);
PROVIDE_HIDDEN(mextern_IRQ_Handler     = DefaultHandler);

/* 异常处理函数 */
PROVIDE_HIDDEN(Exception_Handler       = DefaultHandler);
