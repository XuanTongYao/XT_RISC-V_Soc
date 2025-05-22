#ifndef I2C_H
#define I2C_H
#include "type.h"
#include "addr_define.h"


//----------寄存器定义----------//
typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t : 2;
        uint8_t SDA_DEL_SEL : 2;
        uint8_t : 1;
        uint8_t WKUPEN : 1;
        uint8_t GCEN : 1;
        uint8_t I2CEN : 1;
    };
}I2C_Control;
#define I2C_1_CON_REG ((volatile I2C_Control*)(I2C_PRIMARY_BASE + 0))
#define I2C_2_CON_REG ((volatile I2C_Control*)(I2C_SECONDARY_BASE + 0))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t : 2;
        uint8_t CKSDIS : 1;
        uint8_t ACK : 1;
        uint8_t WR : 1;
        uint8_t RD : 1;
        uint8_t STO : 1;
        uint8_t STA : 1;
    };
}I2C_Command;
#define I2C_1_CMD_REG ((volatile I2C_Command*)(I2C_PRIMARY_BASE + 1))
#define I2C_2_CMD_REG ((volatile I2C_Command*)(I2C_SECONDARY_BASE + 1))

#define I2C_1_BR0_REG ((byte_reg_ptr)(I2C_PRIMARY_BASE + 2))
#define I2C_2_BR0_REG ((byte_reg_ptr)(I2C_SECONDARY_BASE + 2))
// BR1的高6位不能读写
#define I2C_1_BR1_REG ((byte_reg_ptr)(I2C_PRIMARY_BASE + 3))
// BR1的高6位不能读写
#define I2C_2_BR1_REG ((byte_reg_ptr)(I2C_SECONDARY_BASE + 3))

#define I2C_1_TX_DATA_REG ((byte_reg_ptr)(I2C_PRIMARY_BASE + 4))
#define I2C_2_TX_DATA_REG ((byte_reg_ptr)(I2C_SECONDARY_BASE + 4))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t HGC : 1;
        uint8_t TROE : 1;
        uint8_t TRRDY : 1;
        uint8_t ARBL : 1;
        uint8_t SRW : 1;
        uint8_t RARC : 1;
        uint8_t BUSY : 1;
        uint8_t TIP : 1;
    };
}I2C_Status;
#define I2C_1_STATUS_REG ((const volatile I2C_Status*)(I2C_PRIMARY_BASE + 5))
#define I2C_2_STATUS_REG ((const volatile I2C_Status*)(I2C_SECONDARY_BASE + 5))

#define I2C_1_GENERAL_CALL_REG ((ro_byte_reg_ptr)(I2C_PRIMARY_BASE + 6))
#define I2C_2_GENERAL_CALL_REG ((ro_byte_reg_ptr)(I2C_SECONDARY_BASE + 6))

#define I2C_1_RX_DATA_REG ((ro_byte_reg_ptr)(I2C_PRIMARY_BASE + 7))
#define I2C_2_RX_DATA_REG ((ro_byte_reg_ptr)(I2C_SECONDARY_BASE + 7))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQHGC : 1;
        uint8_t IRQTROE : 1;
        uint8_t IRQTRRDY : 1;
        uint8_t IRQARBL : 1;
        uint8_t : 4;
    };
}I2C_InterruptStatus;
#define I2C_1_INT_STATUS_REG ((volatile I2C_InterruptStatus*)(I2C_PRIMARY_BASE + 8))
#define I2C_2_INT_STATUS_REG ((volatile I2C_InterruptStatus*)(I2C_SECONDARY_BASE + 8))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQHGCEN : 1;
        uint8_t IRQTROEEN : 1;
        uint8_t IRQTRRDYEN : 1;
        uint8_t IRQARBLEN : 1;
        uint8_t : 4;
    };
}I2C_InterruptEnable;
#define I2C_1_INT_EN_REG ((volatile I2C_InterruptEnable*)(I2C_PRIMARY_BASE + 9))
#define I2C_2_INT_EN_REG ((volatile I2C_InterruptEnable*)(I2C_SECONDARY_BASE + 9))


typedef struct
{
    volatile I2C_Control CON_REG;
    volatile I2C_Command CMD_REG;
    volatile uint8_t BR0_REG;
    volatile uint8_t BR1_REG;
    volatile uint8_t TX_DATA_REG;
    volatile const I2C_Status STATUS_REG;
    volatile const uint8_t GENERAL_CALL_REG;
    volatile const uint8_t RX_DATA_REG;
    volatile I2C_InterruptStatus INT_STATUS_REG;
    volatile I2C_InterruptEnable INT_EN_REG;
}I2C;
#define I2C_1 ((I2C*)(I2C_PRIMARY_BASE))
#define I2C_2 ((I2C*)(I2C_SECONDARY_BASE))


//----------函数定义----------//


void i2c_tx_addr_only_block(I2C* i2c, const uint8_t addr);

void i2c_tx_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num);

void i2c_rx_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num, const size_t read_num);



#endif
