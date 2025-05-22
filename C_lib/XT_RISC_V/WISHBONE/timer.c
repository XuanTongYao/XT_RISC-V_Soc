#include "timer.h"


void set_top(uint16_t val) {
    *TIMER_SET_TOP_L_REG = val;
    *TIMER_SET_TOP_H_REG = val >> 8;
}

void set_compare(uint16_t val) {
    *TIMER_SET_COMPARE_L_REG = val;
    *TIMER_SET_COMPARE_H_REG = val >> 8;
}

uint16_t get_top(void) {
    uint16_t val = 0;
    val = *TIMER_TOP_L_REG;
    val |= *TIMER_TOP_H_REG << 8;
    return val;
}

uint16_t get_compare(void) {
    uint16_t val = 0;
    val = *TIMER_COMPARE_L_REG;
    val |= *TIMER_COMPARE_H_REG << 8;
    return val;
}

uint16_t get_counter(void) {
    uint16_t val = 0;
    val = *TIMER_CNT_L_REG;
    val |= *TIMER_CNT_H_REG << 8;
    return val;
}
