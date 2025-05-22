#include "uart.h"

uint8_t rx_block(void) {
    while (1) {
        if (UART_STATE_REG->rx_end) {
            return *UART_DATA_REG;
        }
    }
}


void tx_block(uint8_t data) {
    while (1) {
        if (UART_STATE_REG->tx_ready) {
            *UART_DATA_REG = data;
            break;
        }
    }
}

void tx_bytes_block(uint8_t* data, const size_t num, const uint8_t big_endian) {
    for (size_t i = 0; i < num; i++) {
        while (1) {
            if (UART_STATE_REG->tx_ready) {
                if (big_endian) {
                    *UART_DATA_REG = data[num - 1 - i];
                } else {
                    *UART_DATA_REG = data[i];
                }
                break;
            }
        }
    }
}


