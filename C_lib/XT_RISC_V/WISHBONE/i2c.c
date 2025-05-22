#include "i2c.h"
#include "XT_RISC_V.h"

uint8_t I2C_DATA_BUFF[8];

// 这里如果使用结构体的话，
// 编译器会对访问的地址进行优化导致出现错误的结果
// 比如要访问地址0x73的字节
// 编译器可能会优化成读取0x72的两个字节然后处理
// 但是外设地址是不可能使用这种方式读取的
// 编译器加入-fstrict-volatile-bitfields选项即可解决

    // *I2C_1_TX_DATA_REG = addr;
    // I2C_1_CMD_REG->reg = 0x94;// 开始条件+发送
    // while (1) {
    //     if (I2C_1_STATUS_REG->TRRDY) {
    //         DELAY_NOP_10US(6);
    //         break;
    //     }
    // }
    // I2C_1_CMD_REG->reg = 0x44;
            // DELAY_NOP_10US(6);

void i2c_tx_addr_only_block(I2C* i2c, const uint8_t addr) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;// 开始条件+发送
    while (1) {
        if (i2c->STATUS_REG.TRRDY) {
            break;
        }
    }
    i2c->CMD_REG.reg = 0x44;
}


void i2c_tx_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;
    while (1) {
        if (i2c->STATUS_REG.TRRDY) {
            break;
        }
    }
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (1) {
            if (i2c->STATUS_REG.TRRDY) {
                break;
            }
        }
    }
    i2c->CMD_REG.reg = 0x44;
}

void i2c_rx_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num, const size_t read_num) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;
    while (1) {
        if (i2c->STATUS_REG.TRRDY) {
            break;
        }
    }
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (1) {
            if (i2c->STATUS_REG.TRRDY) {
                break;
            }
        }
    }
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;
    while (1) {
        if (i2c->STATUS_REG.SRW) {
            break;
        }
    }
    i2c->CMD_REG.reg = 0x24;
    size_t i = 0;
    for (; i < read_num - 1; i++) {
        while (1) {
            if (i2c->STATUS_REG.TRRDY) {
                break;
            }
        }
        I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    }
    i2c->CMD_REG.reg = 0x6C;
    while (1) {
        if (i2c->STATUS_REG.TRRDY) {
            break;
        }
    }
    I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    i2c->CMD_REG.reg = 0x04;
}


































