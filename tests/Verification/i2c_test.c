#include "XT_RISC_V_Base.h"
#include "uart.h"
#include "i2c.h"

#define SSD1306_ADDR 0x78

__attribute__((noreturn)) void main(void) {
    ENABLE_MEI;
    *EINT_CTRL_ENABLE_REG = UART_IRQ_MASK;
    ENABLE_GLOBAL_MINT;
    while (1) {
        NOP;
    }
}

uint8_t data_0[] = { 0x00,0xA1,0xC8,0x8D,0x14,0xAF,0x20,0x00 };
uint8_t data_1[] = { 0x00,0xAE,0x8D,0x10 };
uint8_t data_2[] = { 0x80,0xA4 };
uint8_t data_3[] = { 0x80,0xA5 };
uint8_t data_4[] = { 0xC0,0x00 };
uint8_t data_5[] = { 0xC0,0xFF };
uint8_t data_6[] = { 0x40,0x00,0x08,0xFC,0x00,0x00,0xC4,0xA4,0x9C,0x00,0x94,0x9C,0xE4,0x20,0x50,0x48,0xFC,0x00,0x9C,0x94,0xF4 };

IRQ UART_RX_IRQ_Handler(void) {
    uint8_t data = *UART_DATA_REG;
    if (data == 0x00) {
        master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_0, sizeof(data_0));
    } else if (data == 0x01) {
        master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_1, sizeof(data_1));
    } else if (data == 0x02) {
        master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_2, sizeof(data_2));
    } else if (data == 0x03) {
        master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_3, sizeof(data_3));
    } else if (data == 0x04) {
        for (size_t i = 0; i < 128; i++) {
            master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_4, sizeof(data_4));
        }
    } else if (data == 0x05) {
        for (size_t i = 0; i < 128; i++) {
            master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_5, sizeof(data_5));
        }
    } else if (data == 0x06) {
        master_i2c_write_bytes_block(I2C_1, SSD1306_ADDR, data_6, sizeof(data_6));
    } else if (data == 0x07) {
        tx_block(I2C_1->CON_REG.reg);
    } else if (data == 0x08) {
        tx_block(I2C_1->STATUS_REG.reg);
    }
}