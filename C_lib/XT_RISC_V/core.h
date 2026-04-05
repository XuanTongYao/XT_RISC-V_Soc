#include "asm_macros.h"
#define CORE_FREQ_MHZ   12
#define CORE_FREQ_KHZ   (CORE_FREQ_MHZ*1000)
#define CORE_FREQ_HZ    (CORE_FREQ_MHZ*1000000)


// 使用递减计数**粗略**延时，当`cycles`为奇数时，可能会少一个周期
// 流水线实际循环: `addi->bnez->if_id->id_ex->addi` 循环N次消耗 `(N-1)*4+2` 个周期
#define DELAY(cycles)  do { \
    uint32_t __real_cyc = 1U + ((cycles) / 4U); \
    asm volatile ( \
        "2:\n" \
        "addi %0, %0, -1\n" \
        "bne %0, zero, 2b\n" \
        : "+r" (__real_cyc) \
        : \
        : "memory" \
    ); \
} while(0)
#define DELAY_US(t) DELAY( ((t) * CORE_FREQ_MHZ) )
#define DELAY_MS(t) DELAY( ((t) * CORE_FREQ_KHZ) )
#define DELAY_SEC(t) DELAY( ((t) * CORE_FREQ_HZ) )

