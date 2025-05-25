#include "XT_RISC_V_Base.h"
#include "timer.h"
#include "uart.h"

uint8_t COMPARE = 0;
uint8_t ADD = 0;
void main(void) {
    ENABLE_MEI;
    // ENABLE_MTI;
    // ENABLE_ALL_MINT;
    *EINT_CTRL_ENABLE_REG = UART_IRQ_MASK | Timer_IRQ_MASK;
    ENABLE_GLOBAL_MINT;
    while (1) {
        NOP;
    }
}

void set_1Hz_test(void) {
    set_prescale(DIV_256);
    set_counter_mode(FastPWM);
    set_output_mode(Toggle);
    set_clkedge(RisingEdge);
    set_top(46875);
}

void pwm_test(void) {
    set_prescale(DIV_8);
    set_counter_mode(FastPWM);
    set_output_mode(Set_Clear);
    set_clkedge(FallingEdge);
    set_top(40000);
    set_compare(20000);
}

void breathing_light_test(void) {
    set_prescale(DIV_256);
    set_counter_mode(FastPWM);
    set_output_mode(Set_Clear);
    set_clkedge(RisingEdge);
    set_top(468);
    COMPARE = 0;
    set_compare(COMPARE);
    TIMER_INT_EN_REG->IRQOVFEN = 1;// 开启溢出中断
}

void exit_breathing_light_test(void) {
    TIMER_INT_EN_REG->IRQOVFEN = 0;// 关闭溢出中断
}

void clkdiv_up_test(void) {
    ClkDiv div = TIMER_CON0_REG->PRESCALE;
    if (div < DIV_1024) {
        ++div;
    }
    set_prescale(div);
}

void clkdiv_down_test(void) {
    ClkDiv div = TIMER_CON0_REG->PRESCALE;
    if (div > 0) {
        --div;
    }
    set_prescale(div);
}


IRQ UART_RX_IRQ_Handler(void) {
    uint8_t val = *UART_DATA_REG;
    if (val == 0x01) {
        set_1Hz_test();
    } else if (val == 0x02) {
        pwm_test();
    } else if (val == 0x03) {
        clkdiv_up_test();
    } else if (val == 0x04) {
        clkdiv_down_test();
    } else if (val == 0x05) {
        breathing_light_test();
    } else if (val == 0x06) {
        exit_breathing_light_test();
    } else if (val == 0x07) {
        TIMER_INT_EN_REG->IRQOVFEN = 1;
    }
}

IRQ Timer_IRQ_Handler(void) {
    if (TIMER_INT_STATUS_REG->IRQOVF) {
        TIMER_INT_STATUS_REG->IRQOVF = 1;
    }
    if (COMPARE == 460 || COMPARE == 0) {
        ADD = !ADD;
    }
    if (ADD) {
        COMPARE += 1;
    } else {
        COMPARE -= 1;
    }
    set_compare(COMPARE);
}


