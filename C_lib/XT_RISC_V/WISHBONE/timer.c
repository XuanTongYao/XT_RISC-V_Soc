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

uint16_t get_capture(void) {
    return ((uint16_t)*TIMER_CAPTURE_H_REG << 8) | *TIMER_CNT_L_REG;
}

void set_output_mode(OutputMode mode) {
    TIMER_CON1_REG->OCM = mode;
}

void set_counter_mode(TimerMode mode) {
    TIMER_CON1_REG->TCM = mode;
}

void set_prescale(ClkDiv div) {
    TIMER_CON0_REG->PRESCALE = div;
}

void set_clkedge(ClkEdge edge) {
    TIMER_CON0_REG->CLKEDGE = edge;
}

void set_clksel(ClkSel sel) {
    TIMER_CON0_REG->CLKSEL = sel;
}
