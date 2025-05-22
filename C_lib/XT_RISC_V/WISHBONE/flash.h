#ifndef FLASH_H
#define FLASH_H
#include "type.h"
#include "addr_define.h"


//----------寄存器定义----------//
typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t : 6;
        uint8_t RSTE : 1;
        uint8_t WBCE : 1;
    };
}FlashControl;
#define FLASH_CON_REG ((volatile FlashControl*)(FLASH_BASE + 0))

#define FLASH_W_DATA_REG ((byte_reg_ptr)(FLASH_BASE + 1))

typedef struct
{
    uint8_t I2CACT : 1;
    uint8_t SSPIACT : 1;
    uint8_t RXFF : 1;
    uint8_t RXFE : 1;
    uint8_t TXFF : 1;
    uint8_t TXFE : 1;
    uint8_t : 1;
    uint8_t WBCACT : 1;
}FlashStatus;
#define FLASH_STATE_REG ((const volatile FlashStatus*)(FLASH_BASE + 2))

#define FLASH_R_DATA_REG ((ro_byte_reg_ptr)(FLASH_BASE + 3))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQ_I2CACT : 1;
        uint8_t IRQ_SSPIACT : 1;
        uint8_t IRQ_RXFF : 1;
        uint8_t IRQ_RXFE : 1;
        uint8_t IRQ_TXFF : 1;
        uint8_t IRQ_TXFE : 1;
        uint8_t : 2;
    };
}FlashInterruptStatus;
#define FLASH_IRQ_REG ((volatile FlashInterruptStatus*)(FLASH_BASE + 4))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQ_I2CACT_EN : 1;
        uint8_t IRQ_SSPIACT_EN : 1;
        uint8_t IRQ_RXFF_EN : 1;
        uint8_t IRQ_RXFE_EN : 1;
        uint8_t IRQ_TXFF_EN : 1;
        uint8_t IRQ_TXFE_EN : 1;
        uint8_t : 2;
    };
}FlashInterruptEnable;
#define FLASH_IRQ_EN_REG ((volatile FlashInterruptEnable*)(FLASH_BASE + 5))



//----------命令定义----------//
// LSC和ISC到底指代什么东西，我也不知道，Lattice的手册就是依托答辩
// 通用命令
#define LSC_READ_STATUS 0x3C
#define LSC_CHECK_BUSY 0xF0
#define ISC_NOOP  0xFF
#define ISC_ENABLE_X 0x74
#define ISC_ENABLE  0xC6
#define ISC_DISABLE  0x26
#define LSC_WRITE_ADDRESS  0xB4

// UFM扇区特有命令
#define LSC_INIT_ADDR_UFM 0x47 // 重置UFM地址
#define LSC_READ_TAG 0xCA
#define LSC_ERASE_TAG 0xCB
#define LSC_PROG_TAG 0xC9

// CFG扇区特有命令
#define IDCODE_PUB 0xE0
#define USERCODE 0xC0
#define LSC_REFRESH 0x79
#define LSC_DEVICE_CTRL 0x7D
#define VERIFY_ID 0xE2
#define LSC_INIT_ADDRESS 0x46
#define LSC_READ_INCR_NV 0x73
#define ISC_ERASE 0x0E
#define LSC_PROG_INCR_NV 0x70
#define ISC_PROGRAM_DONE 0x5E
#define ISC_PROGRAM_SECURITY 0xCE
#define ISC_PROGRAM_SECPLUS 0xCF
#define ISC_PROGRAM_USERCODE 0xC2
#define LSC_READ_FEATURE 0xE7
#define LSC_PROG_FEATURE 0xE4
#define LSC_READ_FEABITS 0xFB
#define PROG_TAG 0xF8

// 命令与操作数数量
#define IS_3OP_CMD(CMD)  (\
    (CMD)==ISC_DISABLE||\
    (CMD)==LSC_REFRESH||\
    (CMD)==LSC_DEVICE_CTRL\
    )

// 命令读写定义
#define IS_WRITE_CMD(CMD)  (\
    (CMD)==LSC_PROG_INCR_NV ||\
    (CMD)==LSC_WRITE_ADDRESS || \
    (CMD)==ISC_PROGRAM_USERCODE || \
    (CMD)==LSC_PROG_TAG ||\
    (CMD)==VERIFY_ID ||\
    (CMD)==PROG_TAG\
    )

// 命令读取数据大小定义
#define IS_1B_CMD(CMD) ((CMD)==LSC_CHECK_BUSY)
#define IS_2B_CMD(CMD) ((CMD)==PROG_TAG||(CMD)==LSC_READ_FEABITS)
#define IS_4B_CMD(CMD) (\
    (CMD)==LSC_READ_STATUS || \
    (CMD)==LSC_WRITE_ADDRESS ||\
    (CMD)==USERCODE ||\
    (CMD)==ISC_PROGRAM_USERCODE ||\
    (CMD)==IDCODE_PUB ||\
    (CMD)==VERIFY_ID \
    )

#define IS_8B_CMD(CMD) (\
    (CMD)==LSC_PROG_FEATURE||\
    (CMD)==LSC_READ_FEATURE\
    )

#define IS_16B_CMD(CMD) ((CMD)==LSC_PROG_INCR_NV || (CMD)==LSC_PROG_TAG)

#define IS_XB_CMD(CMD)  (\
    (CMD)==LSC_READ_INCR_NV||\
    (CMD)==LSC_READ_TAG\
    )

// 命令与操作数总长度
typedef enum {
    OP_3 = 3,
    OP_4 = 4
}CMD_OP;

typedef enum {
    CMD_R = 0,
    CMD_W = 1
}CMD_RW;

// 命令数据长度
typedef enum {
    NONE = 0,
    _1B = 1,
    _2B = 2,
    _4B = 4,
    _8B = 8,
    _16B = 16,
    _XB = 32
}CMD_LEN;

#define CMD_OP_LEN(CMD) (IS_3OP_CMD(CMD) ? OP_3 : OP_4)
#define CMD_RW_SEL(CMD) (IS_WRITE_CMD(CMD) ? CMD_W : CMD_R)
#define CMD_RDATA_LEN(CMD) (IS_XB_CMD(CMD) ? _XB : \
    IS_16B_CMD(CMD) ? _16B :\
    IS_8B_CMD(CMD) ? _8B :\
    IS_4B_CMD(CMD) ? _4B :\
    IS_2B_CMD(CMD) ? _2B :\
    IS_1B_CMD(CMD) ? _1B : NONE\
    )
#define CMD_PARAM(CMD) CMD_OP_LEN(CMD),CMD_RDATA_LEN(CMD),CMD_RW_SEL(CMD)



//----------快速命令----------//
// 实际上NOP指令的操作数可以没有
#define FLASH_NOP FLASH_CON_REG->reg=0x80;\
    *FLASH_W_DATA_REG=ISC_NOOP;\
    FLASH_CON_REG->reg=0x00;


//----------其他----------//
#define TOTAL_PAGE 767
#define MAX_PAGE_ADDR 766
#define BUFF_LEN 32
#define PAGE_BYTES 16
#define PAGE_MASK 0x3FFF
extern uint8_t DATA_BUFF[BUFF_LEN];
extern size_t DATA_LEN;
extern uint32_t CMD_OPERANDS_BE;// 命令+操作数(大端序，最高字节是操作数)
#define CMD_OPERANDS_BE_BYTES ((uint8_t*)(&CMD_OPERANDS_BE))
#define SET_CMD_OPERANDS_BE(CMD,OPERANDS) CMD_OPERANDS_BE=((CMD<<24)|OPERANDS);


//----------函数定义----------//
void reset_flash(void);
uint32_t get_flash_id(void);

/// @brief 发出命令帧并读取对应数据
/// @param 所有项 用CMD_PARAM宏填充
/// @warning 不可重入，非线程安全
/// @warning 调用前必须用SET_CMD_OPERANDS_BE修改命令与操作数
void command_frame(const CMD_OP operand_num, const CMD_LEN data_len, const CMD_RW rw);

void wait_not_busy(void);

/// @brief 启用UFM透明传输
void enable_transparent_UFM(void);

/// @brief 关闭UFM透明传输
void disable_transparent_UFM(void);

//// 下面的函数都必须先启用UFM透明传输!!!

/// @brief 设置页地址
/// @param addr 地址
/// @warning 必须先启用UFM透明传输
void set_UFM_addr(const uint16_t addr);

/// @brief 指定地址读取一页数据
/// @param addr 地址
/// @warning 必须先启用UFM透明传输
/// @warning 会修改DATA_BUFF
void read_one_UFM_page(uint16_t addr);

/// @brief 指定地址写入一页数据
/// @param addr 地址
/// @param data 数据
/// @warning 必须先启用UFM透明传输
/// @warning 写入前必须确保页被擦除否则无效
void write_one_UFM_page(const uint16_t addr, uint8_t* data);

/// @brief 从下一个地址读取一页数据
/// @attention Flash硬件 支持地址自增
void continue_read_one_UFM_page(void);

/// @brief 对下一个地址写入一页数据
/// @attention Flash硬件 支持地址自增
void continue_write_one_UFM_page(uint8_t* data);

/// @brief 擦除UFM扇区
/// @warning 必须先启用UFM透明传输
void erase_UFM(void);




#endif
