#ifndef EINT_CTRL_H
#define EINT_CTRL_H
#include "type.h"
#include "addr_define.h"

#define UART_IRQ_MASK       0x0001

#define I2C1_IRQ_MASK       0x0100
#define I2C2_IRQ_MASK       0x0200
#define SPI_IRQ_MASK        0x0400
#define Timer_IRQ_MASK      0x0800
#define WBC_UFM_IRQ_MASK    0x1000

#define EINT_CTRL_ENABLE_REG ((word_reg_ptr)EINT_CTRL_BASE)
#define EINT_CTRL_PENDING_REG ((ro_word_reg_ptr)(EINT_CTRL_BASE+4))

#endif
