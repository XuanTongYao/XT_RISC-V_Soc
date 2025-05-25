#include "system_timer.h"

void set_mtimecmp(uint64_t val) {
    uint32_t high = (uint32_t)(val >> 32);
    uint32_t low = (uint32_t)val;
    *_MTIMECMP_L_REG = 0xFFFFFFFF;
    *_MTIMECMP_H_REG = high;
    *_MTIMECMP_L_REG = low;
}

uint64_t get_mtime(void) {
    while (1) {
        uint32_t high = *_MTIME_H_REG;
        uint32_t low = *_MTIME_L_REG;
        if (high == *_MTIME_H_REG) {
            return ((uint64_t)high << 32) | low;
        }
    }
}
