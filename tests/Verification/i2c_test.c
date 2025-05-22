#include "XT_RISC_V.h"
#include "i2c.h"

#define SSD1306_ADDR 0x78

__attribute__((noreturn)) void main(void) {
    while (1) {
        UART_STATE state = *UART_STATE_REG;
        if (state.rx_end) {
            uint8_t data = *UART_DATA_REG;
            if (data == 0x00) {
                uint8_t data[] = { 0x00,0xA1,0xC8,0x8D,0x14,0xAF,0x20,0x00 };
                i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
            } else if (data == 0x01) {
                uint8_t data[] = { 0x00,0xAE,0x8D,0x10 };
                i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
            } else if (data == 0x02) {
                uint8_t data[] = { 0x80,0xA4 };
                i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
            } else if (data == 0x03) {
                uint8_t data[] = { 0x80,0xA5 };
                i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
            } else if (data == 0x04) {
                uint8_t data[] = { 0xC0,0x00 };
                for (size_t i = 0; i < 128; i++) {
                    i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
                }
            } else if (data == 0x05) {
                uint8_t data[] = { 0xC0,0xFF };
                for (size_t i = 0; i < 128; i++) {
                    i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
                }
            } else if (data == 0x06) {
                // uint8_t data[] = { 0x40,0x00,0x08,0xFC,0x00,0x00,0xC4,0xA4,0x9C,0x00,0x94,0x9C,0xE4,0x20,0x50,0x48,0xFC,0x00,0x9C,0x94,0xF4 };
                // i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, data, sizeof(data));
            }
        }
        tx_block(0Xff);
    }
}



// uint8_t data[] = { 0x00,0xAE,0x8D,0x10 };
// uint32_t data = 0x108DAE00;
// i2c_tx_bytes_block(I2C_1, SSD1306_ADDR, (uint8_t*)&data, sizeof(data));
// if (state.rx_end) {
//     uint8_t sel = *UART_DATA_REG;
//     byte_reg_ptr addr = ((byte_reg_ptr)(I2C_PRIMARY_BASE + rx_block()));
//     if (sel == 0x00) {
//         // 读
//         *LEDSD_REG = *addr;
//     } else {
//         // 写
//         uint8_t data = rx_block();
//         *LEDSD_REG = data;
//         *addr = data;
//     }
// }