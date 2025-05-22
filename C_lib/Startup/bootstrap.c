//----------自举启动与DEBUG----------//
#include "XT_RISC_V.h"
#include "bootstrap.h"

// 取消分页表
// 反正只有12KB的空间，随便一个程序都满了
// 旧版本bootload程序都有1320 Byte了
// 不相信10W擦写寿命的Flash能这么快用完


// 启动流程：上电进入自举启动模式，启动完成后进入用户代码模式
// 自举启动：
// 1. 检测下载引脚状态
// 2. 选择下载模式
// 3. 读取UFM第1页判断代码有效性
// 4. 将所有指令和数据复制到RAM中
// 5. 进入用户代码模式
__attribute__((noreturn)) void main(void) {
    while (1) {
        reset_flash();
        __enable_transparent_UFM();
        check_UFM();
        if (*DEBUG_REG) {
            download();
        }
        if (__PROG_INFO->fail) {
            while (1) {
                *PRELOAD_STR_INIT_ADDR_REG = STR_ERR;
                __tx_bytes_block_auto_increment(STR_ERR_LEN);
            }
        } else {
            boot();
        }
    }
}

void boot(void) {
    // 必须使用最高内存区的栈
    // 防止全局变量被覆盖
    __set_UFM_addr(0);
    for (size_t i = 0, ram_32addr = 0; i < (MAX_TEXT_DATA_LEN >> 4); i++) {
        __continue_read_one_UFM_page();
        for (size_t i = 0; i < 4; i++, ram_32addr++) {
            INST_BASE_ADDR[ram_32addr] = __DATA_BUFF_32[i];
        }
    }
    // TODO还需要手动清空全局区的内容
    __disable_transparent_UFM();
    *DEBUG_REG = 0xF0;
    asm("j 0x0");
}

#define WAIT_CMD STR_1
#define WAIT_LEN STR_2
#define WAIT_START_FLAG STR_3
#define WAIT_CONFIRM STR_4
// 下载模式：
// 1. 从串口选择进入下载模式/自举启动
// 2. 等待下载指令
// 3. 等待输入即将下载的页面长度
// 4. 计算是否需要擦除和页面地址
// 5. 完成确认
void download(void) {
    // 状态机状态就是字符串起始地址(简化)
    uint8_t user_stage = WAIT_CMD;
    uint8_t str_len = STR_1_LEN;
    PROG_INFO prog_info_tmp = { 0,0 };
    while (1) {
        UART_STATE state = *UART_STATE_REG;
        if (state.rx_end) {
            uint8_t uart_cmd = *UART_DATA_REG;
            if (user_stage == WAIT_CMD) {
                if (uart_cmd == 0x56) {
                    // 进入下载模式
                    user_stage = WAIT_LEN;
                    str_len = STR_2_LEN;
                } else if (uart_cmd == 0xF1) {
                    break;
                }
            } else if (user_stage == WAIT_LEN) {
                // 接收两字节的页面长度(MSB)
                uint16_t page_num = 0;
                page_num |= (uart_cmd << 8);
                page_num |= rx_block();
                // 检查是否有足够的空间存放
                if (page_num > MAX_PAGE || page_num == 0) {
                    *PRELOAD_STR_INIT_ADDR_REG = STR_ERR;
                    __tx_bytes_block_auto_increment(STR_ERR_LEN);
                } else {
                    prog_info_tmp.page_len = page_num;
                    user_stage = WAIT_START_FLAG;
                    str_len = STR_3_LEN;
                }
            } else if (user_stage == WAIT_START_FLAG) {
                if (uart_cmd == 0x78) {
                    // 一定会擦除
                    *__PROG_INFO = prog_info_tmp;
                    __erase_UFM();
                    from_uart_download();
                    user_stage = WAIT_CONFIRM;
                    str_len = STR_4_LEN;
                }
            } else if (user_stage == WAIT_CONFIRM) {
                if (uart_cmd == 0x57) {
                    user_stage = WAIT_CMD;
                    str_len = STR_1_LEN;
                }
            }
        }
        *PRELOAD_STR_INIT_ADDR_REG = user_stage;
        __tx_bytes_block_auto_increment(str_len);
        // FIXME 由于这里有阻塞发送，此时如果接收到多字节数据，会漏掉
    }
}


void from_uart_download(void) {
    __set_UFM_addr(0);
    for (size_t page = 0; page < __PROG_INFO->page_len; page++) {
        for (size_t j = 0; j < PAGE_BYTES; j++) {
            __DATA_BUFF_8[j] = rx_block();
        }
        __continue_manual_write_one_UFM_page();
    }
}


void check_UFM(void) {
    __read_one_UFM_page(0);
    // 第0个字为全0，则为无效程序代码或ELF
    // TODO需要简单解析ELF
    __PROG_INFO->fail = __DATA_BUFF_32[0] == 0;
    __PROG_INFO->page_len = 0;
}


void __tx_bytes_block_auto_increment(const size_t num) {
    for (size_t i = 0; i < num; i++) {
        while (1) {
            if (UART_STATE_REG->tx_ready) {
                *UART_DATA_REG = *PRELOAD_STR_AUTO_INC_REG;
                break;
            }
        }
    }
}


void __command_frame(const CMD_OP operand_num, const CMD_LEN data_len, const CMD_RW rw) {
    FLASH_CON_REG->reg = 0x80;

    // 写入命令与操作数
    for (size_t i = 0; i < operand_num; i++) {
        *FLASH_W_DATA_REG = __CMD_OPERANDS_BE_BYTES[3 - i];
    }

    // 固定数据长度读写数据
    for (size_t i = 0; i < data_len; i++) {
        if (rw == CMD_R) {
            __DATA_BUFF_8[i] = *FLASH_R_DATA_REG;
        } else {
            *FLASH_W_DATA_REG = __DATA_BUFF_8[i];
        }
    }
    FLASH_CON_REG->reg = 0x00;
}

void __wait_not_busy(void) {
    // 直接等250us
    DELAY_NOP_10US(25);
}

void __enable_transparent_UFM(void) {
    __SET_CMD_OPERANDS_BE(ISC_ENABLE_X, 0x080000);
    __command_frame(CMD_PARAM(ISC_ENABLE_X));
    __wait_not_busy();
}

void __disable_transparent_UFM(void) {
    __SET_CMD_OPERANDS_BE(ISC_DISABLE, 0);
    __command_frame(CMD_PARAM(ISC_DISABLE));
    FLASH_NOP;
}

void __set_UFM_addr(const uint16_t addr) {
    __DATA_BUFF_16[0] = 0x0040;
    // 这里地址还是要先传输高位
    __DATA_BUFF_8[2] = (addr & 0x3FFF) >> 8;__DATA_BUFF_8[3] = addr & 0x3FFF;
    __SET_CMD_OPERANDS_BE(LSC_WRITE_ADDRESS, 0);
    __command_frame(CMD_PARAM(LSC_WRITE_ADDRESS));
}

void __read_one_UFM_page(const uint16_t addr) {
    // 设置页地址
    __set_UFM_addr(addr);
    // 读取到1页数据
    __SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    __command_frame(CMD_PARAM(LSC_READ_TAG));
}

void __continue_read_one_UFM_page(void) {
    __SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    __command_frame(CMD_PARAM(LSC_READ_TAG));
}

void __continue_manual_write_one_UFM_page() {
    __SET_CMD_OPERANDS_BE(LSC_PROG_TAG, 0x000001);
    __command_frame(CMD_PARAM(LSC_PROG_TAG));
    __wait_not_busy();
}

void __erase_UFM(void) {
    __SET_CMD_OPERANDS_BE(LSC_ERASE_TAG, 0);
    __command_frame(CMD_PARAM(LSC_ERASE_TAG));
    // 直接等1000ms
    DELAY_NOP_MS(1200);
}


