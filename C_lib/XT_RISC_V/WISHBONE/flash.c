#include "flash.h"

size_t DATA_LEN = 0;
uint8_t DATA_BUFF[BUFF_LEN] = { 0 };
uint32_t CMD_OPERANDS_BE = 0;

void reset_flash(void) {
    FLASH_CON_REG->reg = 0x40;
    FLASH_CON_REG->reg = 0x00;
}

uint32_t get_flash_id(void) {
    FLASH_CON_REG->reg = 0x80;
    *FLASH_W_DATA_REG = 0xE0;
    *FLASH_W_DATA_REG = 0x00;
    *FLASH_W_DATA_REG = 0x00;
    *FLASH_W_DATA_REG = 0x00;
    uint8_t buff[4];
    buff[0] = *FLASH_R_DATA_REG;
    buff[1] = *FLASH_R_DATA_REG;
    buff[2] = *FLASH_R_DATA_REG;
    buff[3] = *FLASH_R_DATA_REG;
    FLASH_CON_REG->reg = 0x00;
    return  (buff[0] << 24) | (buff[1] << 16) | (buff[2] << 8) | buff[3];
}

void command_frame(const CMD_OP operand_num, const CMD_LEN data_len, const CMD_RW rw) {
    FLASH_CON_REG->reg = 0x80;

    // 写入命令与操作数
    for (size_t i = 0; i < operand_num; i++) {
        *FLASH_W_DATA_REG = CMD_OPERANDS_BE_BYTES[3 - i];
    }

    if (data_len == _XB) {
        uint16_t num_pages = PAGE_MASK & CMD_OPERANDS_BE;
        size_t perfix_dummys = 0;
        size_t postfix_dummys = 0;
        if (num_pages > 1) {
            num_pages--;// 文档要求的-1
            if (CMD_OPERANDS_BE_BYTES[2] == 0x10) {
                perfix_dummys = PAGE_BYTES;
            } else {
                perfix_dummys = 2 * PAGE_BYTES;
                postfix_dummys = 4;
            }
        }
        DATA_LEN = PAGE_BYTES * num_pages;

        // 读取
        // 忽略无用前缀数据
        for (size_t i = 0; i < perfix_dummys; i++) {
            *FLASH_R_DATA_REG;
        }
        // 读取页数据
        for (size_t i = 0, buff_index = 0; i < num_pages; i++) {
            for (size_t i = 0; i < PAGE_BYTES; i++, buff_index++) {
                DATA_BUFF[buff_index] = *FLASH_R_DATA_REG;
            }
            // 忽略尾随无用数据
            for (size_t i = 0; i < postfix_dummys; i++) {
                *FLASH_R_DATA_REG;
            }
        }
    } else if (data_len != NONE) {
        // 固定数据长度读写数据
        DATA_LEN = data_len;
        for (size_t i = 0; i < data_len; i++) {
            if (rw == CMD_R) {
                DATA_BUFF[i] = *FLASH_R_DATA_REG;
            } else {
                *FLASH_W_DATA_REG = DATA_BUFF[i];
            }
        }
    }
    FLASH_CON_REG->reg = 0x00;
}

void wait_not_busy(void) {
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            return;
        }
    }
}

void enable_transparent_UFM(void) {
    SET_CMD_OPERANDS_BE(ISC_ENABLE_X, 0x080000);
    command_frame(CMD_PARAM(ISC_ENABLE_X));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

void disable_transparent_UFM(void) {
    SET_CMD_OPERANDS_BE(ISC_DISABLE, 0);
    command_frame(CMD_PARAM(ISC_DISABLE));
    FLASH_NOP;
}

void set_UFM_addr(const uint16_t addr) {
    DATA_BUFF[0] = 0x40;DATA_BUFF[1] = 0x00;
    DATA_BUFF[2] = (addr & 0x3FFF) >> 8;DATA_BUFF[3] = addr & 0x3FFF;
    SET_CMD_OPERANDS_BE(LSC_WRITE_ADDRESS, 0);
    command_frame(CMD_PARAM(LSC_WRITE_ADDRESS));
}

void read_one_UFM_page(uint16_t addr) {
    if (addr == 0) {
        SET_CMD_OPERANDS_BE(LSC_INIT_ADDR_UFM, 0);
        command_frame(CMD_PARAM(LSC_INIT_ADDR_UFM));
    } else {
        set_UFM_addr(addr);
    }
    // 读取到1页数据
    SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    command_frame(CMD_PARAM(LSC_READ_TAG));
}

void write_one_UFM_page(const uint16_t addr, uint8_t* data) {
    set_UFM_addr(addr);
    for (size_t i = 0; i < PAGE_BYTES; i++) {
        DATA_BUFF[i] = data[i];
    }
    SET_CMD_OPERANDS_BE(LSC_PROG_TAG, 0x000001);
    command_frame(CMD_PARAM(LSC_PROG_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

void continue_read_one_UFM_page(void) {
    SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    command_frame(CMD_PARAM(LSC_READ_TAG));
}

void continue_write_one_UFM_page(uint8_t* data) {
    for (size_t i = 0; i < PAGE_BYTES; i++) {
        DATA_BUFF[i] = data[i];
    }
    SET_CMD_OPERANDS_BE(LSC_PROG_TAG, 0x000001);
    command_frame(CMD_PARAM(LSC_PROG_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

void erase_UFM(void) {
    SET_CMD_OPERANDS_BE(LSC_ERASE_TAG, 0);
    command_frame(CMD_PARAM(LSC_ERASE_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

