// 特权指令测试
#define XT_RISCV_MCU_IMPLEMENTATION
#define XTRISCV_ONLY_UART
#define XTRISCV_ONLY_EINT_CTRL
#define XTRV32I_LB_IMPLEMENTATION
#define XTLB_ONLY_LEDSD
#include "c/xt_riscv_mcu.h"
#include "c/xtrv32i_lb.h"
#include "c/asm_macros.h"

void main(void) {
    ENABLE_MEI;
    *EINT_CTRL_ENABLE_REG = 0xFFFFFFFF;
    ENABLE_GLOBAL_MINT;
    while (true) {
        for (size_t i = 0; i < 10; i++) {
            *LEDSD_REG = i;
            DELAY_SEC(1);
        }
        WFI;
        DELAY_SEC(1);
        ECALL;
        DELAY_SEC(1);
    }
}

IRQ UART_RX_IRQ_Handler(void) {
    *LEDSD_REG = *UART_DATA_REG;
}


void Ecall_ErrorHandler(void) {
    *LEDSD_REG = 0xEC;
    EXCEPTION_SKIP;
}
