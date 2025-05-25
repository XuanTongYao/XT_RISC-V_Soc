#ifndef SYSTEM_TIMER_H
#define SYSTEM_TIMER_H
#include "type.h"
#include "addr_define.h"

#define SYSTEM_TIMER_FREQ 1000000
#define SYSTEM_TIMER_MS_CNT (SYSTEM_TIMER_FREQ/1000)
#define SYSTEM_TIMER_US_CNT (SYSTEM_TIMER_FREQ/1000000)

#define __MTIME_REG ((dword_reg_ptr)SYSTEM_TIMER_BASE)
#define _MTIME_L_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+0))
#define _MTIME_H_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+4))
#define __MTIMECMP_REG ((dword_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define _MTIMECMP_L_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define _MTIMECMP_H_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+12))

void set_mtimecmp(uint64_t val);

uint64_t get_mtime(void);

#endif
