#ifndef KEY_SW_H
#define KEY_SW_H
#include "type.h"
#include "addr_define.h"

//----------按键部分----------//
#define KEY_NUM 4
#define KEY_REG ((half_reg_ptr)(KEY_SW_BASE+0)) // 按下时为高电平(已经在硬件做了翻转)

//----------开关部分----------//
#define SWITCH_NUM 3
#define SWITCH_REG ((half_reg_ptr)(KEY_SW_BASE+2))

#endif
