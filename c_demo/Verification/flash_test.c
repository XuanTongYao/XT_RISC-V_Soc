#define XT_RISCV_MCU_IMPLEMENTATION
#define XTRISCV_ONLY_UART
#define XTRV32I_WISBONE_IMPLEMENTATION
#define XTWISBONE_ONLY_FLASH
#include "c/xt_riscv_mcu.h"
#include "c/xtrv32i_wisbone.h"

static uint8_t data[PAGE_BYTES] = { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 };
void main(void) {
    reset_flash();
    enable_transparent_UFM();
    while (true) {
        UART_STATE state = *UART_STATE_REG;
        if (state.rx_end) {
            uint8_t addr = *UART_DATA_REG;
            if (addr == 0xFF) {
                SET_CMD_OPERANDS_BE(IDCODE_PUB, 0);
                command_frame(CMD_PARAM(IDCODE_PUB));
            } else if (addr == 0xFE) {
                disable_transparent_UFM();
            } else if (addr == 0xF1) {
                write_one_UFM_page(0x03, data);
            } else {
                read_one_UFM_page(addr);
                tx_block(0xF1);
            }
            // *LEDSD_REG = addr;
            tx_bytes_block(DATA_BUFF, DATA_LEN, false);
        } else if (state.tx_ready) {
            // 发送成功
            *UART_DATA_REG = 0x00;
        }
    }
}

// void main(void) {
//     uint32_t id;
//     reset_flash();
//     while (true) {
//         UART_STATE state = *UART_STATE_REG;
//         if (state.rx_end) {
//             *LEDSD_REG = *UART_DATA_REG;
//             id = get_flash_id();
//             tx_bytes_block((uint8_t*)&id, 4, true);
//         } else if (state.tx_ready) {
//             *UART_DATA_REG = 0x06;
//         }
//     }
// }


