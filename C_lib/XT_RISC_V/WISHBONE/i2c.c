#include "i2c.h"
#include "XT_RISC_V.h"

uint8_t I2C_DATA_BUFF[8];

// 这里如果使用结构体的话，
// 编译器会对访问的地址进行优化导致出现错误的结果
// 比如要访问地址0x73的字节
// 编译器可能会优化成读取0x72的两个字节然后处理
// 但是外设地址是不可能使用这种方式读取的
// 编译器加入-fstrict-volatile-bitfields选项即可解决

void set_i2c_prescale(I2C* i2c, uint16_t div) {
    div &= 0x3FF;
    i2c->BR0_REG = (uint8_t)div;
    i2c->BR1_REG = (uint8_t)(div >> 8);
}

uint16_t get_i2c_prescale(I2C* i2c) {
    uint16_t val = i2c->BR0_REG;
    val |= ((uint16_t)i2c->BR1_REG << 8);
    return val;
}

void reset_i2c(I2C* i2c) {
    i2c->CON_REG.I2CEN = 0;
    DELAY_NOP_10US(5);
    i2c->CON_REG.I2CEN = 1;
}

void master_i2c_write_addr_only_block(I2C* i2c, const uint8_t addr) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;// 开始条件+发送
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    i2c->CMD_REG.reg = 0x44;
}


void master_i2c_write_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num) {
    i2c->TX_DATA_REG = addr & 0xFE;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (!i2c->STATUS_REG.TRRDY) {}
        DELAY_NOP_10US(4);
    }
    i2c->CMD_REG.reg = 0x44;
}

void master_i2c_read_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num, const size_t read_num) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (!i2c->STATUS_REG.TRRDY) {}
        DELAY_NOP_10US(4);
    }
    i2c->TX_DATA_REG = addr | 0x01;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.SRW) {}
    i2c->CMD_REG.reg = 0x24;
    size_t i = 0;
    for (;i < read_num - 1; i++) {
        while (!i2c->STATUS_REG.TRRDY) {}
        I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    }
    DELAY_NOP_10US(4);
    i2c->CMD_REG.reg = 0x6C;
    while (!i2c->STATUS_REG.TRRDY) {}
    I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    // i2c->CMD_REG.reg = 0x04; // 外部存在其他主机时才需要
}


































