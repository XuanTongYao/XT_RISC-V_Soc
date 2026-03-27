#include "XT_RISC_V.h"
#include "Utils.h"

void main(void) {
    while (1) {
        uint16_t key_data = *KEY_REG;
        uint16_t sw_data = *SWITCH_REG;
        if (GetBit(key_data, 0)) {
            *LEDSD_REG = 0x00;
        } else if (GetBit(key_data, 1)) {
            *LEDSD_REG = 0x01;
        } else if (GetBit(key_data, 2)) {
            *LEDSD_REG = 0x02;
        } else if (GetBit(key_data, 3)) {
            *LEDSD_REG = 0x03;
        } else if (GetBit(sw_data, 0)) {
            *LEDSD_REG = 0x10;
        } else if (GetBit(sw_data, 1)) {
            *LEDSD_REG = 0x20;
        } else if (GetBit(sw_data, 2)) {
            *LEDSD_REG = 0x30;
        }
    }
}


