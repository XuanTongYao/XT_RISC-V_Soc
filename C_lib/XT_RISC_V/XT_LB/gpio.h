#ifndef GPIO_H
#define GPIO_H
#include "type.h"
#include "addr_define.h"

#define GPIO_NUM 30

#define GPIO_DIRECTION_REG ((word_reg_ptr)(GPIO_BASE+0))
#define GPIO_DATA_REG ((word_reg_ptr)(GPIO_BASE+4))

#endif
