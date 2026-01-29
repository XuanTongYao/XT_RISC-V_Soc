#include "flash.h"
#include "Utils.h"
#include "bootstrap_control.h"

#ifdef EMOJI
// 用emoji代替文字

// "💾:0x56,🛫:0xF1"
#define STR_CMD 0
#define STR_CMD_LEN 20
// "Len="
#define STR_LEN 20
#define STR_LEN_LEN 4
// "\n🔛:0x78"
#define STR_START_DOWNLOAD 24
#define STR_START_DOWNLOAD_LEN 10
// "\n✅:0x57"
#define STR_CONFIRM 34
#define STR_CONFIRM_LEN 9
// "\n❌" 
#define STR_ERR 43
#define STR_ERR_LEN 4

#else

// "下载:0x56,启动:0xF1\n"
#define STR_CMD 0
#define STR_CMD_LEN 24
// "Len="
#define STR_LEN 24
#define STR_LEN_LEN 4
// "\n开始:0x78"
#define STR_START_DOWNLOAD 28
#define STR_START_DOWNLOAD_LEN 12
// "\n完成:0x57"
#define STR_CONFIRM 40
#define STR_CONFIRM_LEN 12
// "\nERROR"
#define STR_ERR 52
#define STR_ERR_LEN 6

#endif
// 不能用字符串字面量(需要memcpy调用)，只读数据也不好从单端口ROM读取

#define INST_BASE_ADDR ((volatile uint32_t*)INST_RAM_BASE)
// 如果自举工作在内存中可能会用到
#define BOOTSTRAP_START_WORD_ADDR 512 // 改加载地址记得改boot的跳转地址
#define BOOTSTRAP_REMAIN_PAGES (((BOOTSTRAP_START_WORD_ADDR*4)+PAGE_BYTES-1)>>4) 
#define BOOTSTRAP_LEN 900 // bootstrap程序占用的大小
#define BOOTSTRAP_PAGES ((BOOTSTRAP_LEN+PAGE_BYTES-1)>>4) // bootstrap程序占用的页数
#define BOOTSTRAP_START_PAGE (TOTAL_PAGE-BOOTSTRAP_PAGES) 
// #define MAX_PAGE Min(BOOTSTRAP_REMAIN_PAGES,TOTAL_PAGE-BOOTSTRAP_PAGES)
#define MAX_PAGE Min(INST_RAM_LEN+DATA_RAM_LEN,TOTAL_PAGE)

/// @brief 自举启动
void boot(void);

/// @brief 下载模式
void download(void);

/// @brief 从uart串口下载
void from_uart_download(void);

typedef struct
{
    uint8_t fail;// 无效程序代码或超出长度启动失败
    uint16_t page_len;// 最新有效代码页长度
}PROG_INFO;

/// @brief 检查UFM使用情况，只检查前4个字节是否为0
/// @param  返回最新可用的起始地址与长度
void check_UFM(void);


//----------专为自举的特殊简化函数----------//

// 对齐放在高位地址，防止被指令覆盖
// RISC-V调用约定栈地址为16字节对齐，规避6个调用栈
#define __DATA_BUFF_LEN 16
#define __DATA_BUFF_ADDR (STACK_TOP_ADDR-16-96)
#define __DATA_BUFF_8 ((volatile uint8_t*)__DATA_BUFF_ADDR)
#define __DATA_BUFF_16 ((volatile uint16_t*)__DATA_BUFF_ADDR)
#define __DATA_BUFF_32 ((volatile uint32_t*)__DATA_BUFF_ADDR)

#define __CMD_OPERANDS_BE_32 ((volatile uint32_t*)(__DATA_BUFF_ADDR-4))
#define __CMD_OPERANDS_BE_BYTES ((volatile uint8_t*)(__DATA_BUFF_ADDR-4))
#define __SET_CMD_OPERANDS_BE(CMD,OPERANDS) *__CMD_OPERANDS_BE_32=((CMD<<24)|OPERANDS);

#define __PROG_INFO ((volatile PROG_INFO*)(__DATA_BUFF_ADDR-4-4))


#undef IS_XB_CMD
#undef IS_16B_CMD
#define IS_XB_CMD(CMD)  ((CMD)==LSC_READ_INCR_NV)
#define IS_16B_CMD(CMD) ((CMD)==LSC_PROG_INCR_NV || (CMD)==LSC_PROG_TAG || (CMD)==LSC_READ_TAG)

// 使用自动增地址的硬件实现，还要修改tx函数
void __tx_bytes_block_auto_increment(const size_t num);

/// @brief 发出命令帧并读取对应数据
/// @param operand_num CMD_PARAM宏已填充此项
/// @param data_len CMD_PARAM宏已填充此项
/// @param rw CMD_PARAM宏已填充此项
/// @warning 不可重入，非线程安全
/// @warning 调用前必须手动修改CMD_OPERANDS
void __command_frame(const CMD_OP operand_num, const CMD_LEN data_len, const CMD_RW rw);

void __wait_not_busy(void);

/// @brief 启用UFM透明传输
void __enable_transparent_UFM(void);

/// @brief 关闭UFM透明传输
void __disable_transparent_UFM(void);

/// @brief 重置地址到扇区1页0
void __reset_UFM_addr(void);

// /// @brief 读取一页数据
// /// @param addr 地址
// /// @warning 必须先启用UFM透明传输
// /// @warning 会修改__DATA_BUFF
// void __read_one_UFM_page(const uint16_t addr);

/// @brief 从下一个地址读取一页数据
/// @attention Flash硬件 支持地址自增
/// @warning 必须先启用UFM透明传输
void __continue_read_one_UFM_page(void);

/// @brief 对下一个地址写入一页数据
/// @warning 自行修改__BUFF_DATA
/// @attention Flash硬件 支持地址自增
/// @warning 必须先启用UFM透明传输
void __continue_manual_write_one_UFM_page(void);

/// @brief 擦除UFM扇区
/// @warning 必须先启用UFM透明传输
void __erase_UFM(void);

