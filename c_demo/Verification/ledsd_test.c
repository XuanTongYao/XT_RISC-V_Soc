#define XT_RISCV_MCU_IMPLEMENTATION
#define XTRISCV_ONLY_UART
#define XTRISCV_ONLY_EINT_CTRL
#define XTRISCV_ONLY_MTIMER
#define XTRV32I_LB_IMPLEMENTATION
#define XTLB_ONLY_LEDSD
#define XTLB_ONLY_LED
#include "c/xt_riscv_mcu.h"
#include "c/xtrv32i_lb.h"
#include "c/asm_macros.h"

void main(void) {
    ENABLE_ALL_MINT;
    *EINT_CTRL_ENABLE_REG = UART_IRQ_MASK;
    ENABLE_GLOBAL_MINT;
    while (true) {
        NOP;
    }
}


IRQ UART_RX_IRQ_Handler(void) {
    *LEDSD_REG = *UART_DATA_REG;
}

IRQ mtimer_IRQ_Handler(void) {
    static uint32_t TIME = 0;
    uint64_t systime = get_mtime();
    set_mtimecmp(systime + (1 * SYSTEM_TIMER_FREQ));
    TIME++;
    *LEDSD_REG = (uint8_t)TIME;
    *LED_REG = ~(uint8_t)TIME;
}
