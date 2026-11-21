PROVIDE_HIDDEN(UartRx_IRQ_Handler = DefaultHandler);
PROVIDE_HIDDEN(I2c1_IRQ_Handler = DefaultHandler);
PROVIDE_HIDDEN(I2c2_IRQ_Handler = DefaultHandler);
PROVIDE_HIDDEN(Spi_IRQ_Handler = DefaultHandler);
PROVIDE_HIDDEN(Timer_IRQ_Handler = DefaultHandler);
PROVIDE_HIDDEN(WbcUfm_IRQ_Handler = DefaultHandler);

PROVIDE_HIDDEN(_start_UartRx_trap = DefaultHandler);
PROVIDE_HIDDEN(_start_I2c1_trap = DefaultHandler);
PROVIDE_HIDDEN(_start_I2c2_trap = DefaultHandler);
PROVIDE_HIDDEN(_start_Spi_trap = DefaultHandler);
PROVIDE_HIDDEN(_start_Timer_trap = DefaultHandler);
PROVIDE_HIDDEN(_start_WbcUfm_trap = DefaultHandler);

PROVIDE_HIDDEN(UartRx = DefaultHandler);
PROVIDE_HIDDEN(I2c1 = DefaultHandler);
PROVIDE_HIDDEN(I2c2 = DefaultHandler);
PROVIDE_HIDDEN(Spi = DefaultHandler);
PROVIDE_HIDDEN(Timer = DefaultHandler);
PROVIDE_HIDDEN(WbcUfm = DefaultHandler);
