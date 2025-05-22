#include "XT_RISC_V.h"

uint8_t COMPARE = 0;
uint8_t ADD = 0;
void main(void) {
    // ENABLE_MEI;
    // ENABLE_MTI;
    ENABLE_ALL_MINT;
    *EINT_CTRL_ENABLE_REG = UART_IRQ_MASK;
    ENABLE_GLOBAL_MINT;
    while (1) {
        NOP;
    }
}


IRQ UART_RX_IRQ_Handler(void) {
    *LEDSD_REG = *UART_DATA_REG;
}

IRQ mtimer_IRQ_Handler(void) {
    uint64_t systime = *MTIME_REG;
    *MTIMECMP_REG = systime + (20 * SYSTEM_TIMER_MS_CNT);
    if (COMPARE == 250 || COMPARE == 0) {
        ADD = !ADD;
    }
    if (ADD) {
        COMPARE += 2;
    } else {
        COMPARE -= 2;
    }
    *LEDSD_REG = COMPARE;
    set_compare(COMPARE);
}
