#include "XT_RISC_V.h"

void main(void) {
    uint8_t data[PAGE_BYTES];
    reset_flash();
    for (size_t i = 0; i < PAGE_BYTES; i++) {
        data[i] = i;
    }
    enable_transparent_UFM();
    while (1) {
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
            tx_bytes_block(DATA_BUFF, DATA_LEN, 0);
        } else if (state.tx_ready) {
            // 发送成功
            *UART_DATA_REG = 0x00;
        }
    }
}

// void main(void) {
//     uint32_t id;
//     reset_flash();
//     while (1) {
//         UART_STATE state = *UART_STATE_REG;
//         if (state.rx_end) {
//             *LEDSD_REG = *UART_DATA_REG;
//             id = get_flash_id();
//             tx_bytes_block((uint8_t*)&id, 4, 1);
//         } else if (state.tx_ready) {
//             *UART_DATA_REG = 0x06;
//         }
//     }
// }


