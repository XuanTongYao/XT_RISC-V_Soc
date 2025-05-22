#ifndef EINT_CTRL_H
#define EINT_CTRL_H
#include "type.h"
#include "addr_define.h"

#define UART_IRQ_MASK 0x0001

#define EINT_CTRL_ENABLE_REG ((word_reg_ptr)EINT_CTRL_BASE)
#define EINT_CTRL_PENDING_REG ((ro_word_reg_ptr)(EINT_CTRL_BASE+4))

#endif
