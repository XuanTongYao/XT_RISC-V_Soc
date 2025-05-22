#include "XT_RISC_V.h"

uint32_t TIME = 0;
void main(void) {
    // ENABLE_MEI;
    // *UART_DEBUG_REG = 0x01;
    // ENABLE_MTI;
    ENABLE_ALL_MINT;
    *EINT_CTRL_ENABLE_REG = 0xFFFFFFFF;
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
    *MTIMECMP_REG = systime + (1 * SYSTEM_TIMER_FREQ);
    TIME++;
    *LEDSD_REG = (uint8_t)TIME;
    *LED_REG = ~(uint8_t)TIME;
}
