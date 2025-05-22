// 特权指令测试
#include "XT_RISC_V.h"

void main(void) {
    ENABLE_MEI;
    *EINT_CTRL_ENABLE_REG = 0xFFFFFFFF;
    ENABLE_GLOBAL_MINT;
    while (1) {
        for (size_t i = 0; i < 10; i++) {
            *LEDSD_REG = i;
            DELAY_NOP_SEC(1);
        }
        WFI;
        DELAY_NOP_SEC(1);
        ECALL;
        DELAY_NOP_SEC(1);
    }
}


IRQ UART_RX_IRQ_Handler(void) {
    *LEDSD_REG = *UART_DATA_REG;
}


IRQ Ecall_ErrorHandler(void) {
    *LEDSD_REG = 0xEC;
    EXCEPTION_DONE;
}
