#include "asm_macros.h"
#define CORE_FREQ_MHZ 12


// 使用nop粗略延时
// nop->addi->bnez->if_id->id_ie->nop
// 频率除以5
#define __DELAY_SEC_TIMES (1000000*CORE_FREQ_MHZ/5)
#define __DELAY_MS_TIMES (1000*CORE_FREQ_MHZ/5)
#define __DELAY_10US_TIMES (10*CORE_FREQ_MHZ/5)
#define DELAY_NOP_SEC(SEC) for (size_t i = 0; i < (SEC)*__DELAY_SEC_TIMES; i++) {NOP;}
#define DELAY_NOP_MS(MS) for (size_t i = 0; i < (MS)*__DELAY_MS_TIMES; i++) {NOP;}
#define DELAY_NOP_10US(_10US) for (size_t i = 0; i < (_10US)*__DELAY_10US_TIMES; i++) {NOP;}


