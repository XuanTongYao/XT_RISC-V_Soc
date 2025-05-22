#include "XT_RISC_V.h"

void echo_test(void);
void echo_16byte(void);
void spam_0to9_test(void);
void spam_uint8_test(void);
void tx_bytes_test(void);


void main(void) {
    uint8_t i = 0xff;
    while (1) {
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

void tx_bytes_test(void) {
    uint8_t arr[11];
    arr[0] = 'H';
    arr[1] = 'e';
    arr[2] = 'l';
    arr[3] = 'l';
    arr[4] = 'o';
    arr[5] = ',';
    arr[6] = 'w';
    arr[7] = 'o';
    arr[8] = 'r';
    arr[9] = 'l';
    arr[10] = 'd';
    tx_bytes_block(arr, 11, 0);
}

