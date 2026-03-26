#define XT_RISCV_MCU_IMPLEMENTATION
#define XTRISCV_ONLY_UART
#include "c/xt_riscv_mcu.h"

void echo_test(void);
void echo_16byte(void);
void spam_0to9_test(void);
void spam_uint8_test(void);
void tx_bytes_test(void);


void main(void) {
    while (true) {
        uint8_t cmd = rx_block();
        if (cmd == 0x01) {
            echo_test();
        } else if (cmd == 0x02) {
            echo_16byte();
        } else if (cmd == 0x03) {
            spam_0to9_test();
        } else if (cmd == 0x04) {
            spam_uint8_test();
        } else if (cmd == 0x05) {
            tx_bytes_test();
        }
    }
}

void echo_test(void) {
    uint8_t data = rx_block();
    tx_block(data);
}

void echo_16byte(void) {
    uint8_t tmp[16];
    for (size_t i = 0; i < 16; i++) {
        tmp[i] = rx_block();
    }
    tx_bytes_block(tmp, 16, 0);
}

void spam_0to9_test(void) {
    for (size_t i = 0; i < 10; i++) {
        tx_block(i);
    }
}

void spam_uint8_test(void) {
    for (size_t i = 0; i < 256; i++) {
        tx_block(i);
    }
}

// FIXME 很神奇的bug，!打印不出来
static const char str[] = "Hello, world!";
void tx_bytes_test(void) {
    tx_bytes_block((uint8_t*)str, sizeof(str), false);
}

