#ifndef SYSTEM_TIMER_H
#define SYSTEM_TIMER_H
#include "type.h"
#include "addr_define.h"

#define SYSTEM_TIMER_FREQ 1000000
#define SYSTEM_TIMER_MS_CNT (SYSTEM_TIMER_FREQ/1000)
#define SYSTEM_TIMER_US_CNT (SYSTEM_TIMER_FREQ/1000000)

#define MTIME_REG ((dword_reg_ptr)SYSTEM_TIMER_BASE)
#define MTIME_L_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+0))
#define MTIME_H_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+4))
#define MTIMECMP_REG ((dword_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define MTIMECMP_L_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define MTIMECMP_H_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+12))


#endif
