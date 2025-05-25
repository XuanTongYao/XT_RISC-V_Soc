#ifndef SPI_H
#define SPI_H
#include "type.h"
#include "addr_define.h"


//----------寄存器定义----------//
typedef union
{
    uint8_t reg;
    struct
    {
        // 所有延迟周期的精度为0.5个SCK周期，最短0.5
        // 前导延迟周期
        uint8_t TLead_XCNT : 3;
        // 尾随延迟周期
        uint8_t TTrail_XCNT : 3;
        // 空闲延迟周期
        uint8_t TIdle_XCNT : 2;
    };
}SPI_Control0;
#define SPI_CON0_REG ((volatile SPI_Control0*)(SPI_BASE + 0))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t : 4;
        uint8_t TXEDGE : 1;
        uint8_t WKUPEN_CFG : 1;
        uint8_t WKUPEN_USER : 1;
        uint8_t SPE : 1;
    };
}SPI_Control1;
#define SPI_CON1_REG ((volatile SPI_Control1*)(SPI_BASE + 1))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t LSBF : 1;
        uint8_t CPHA : 1;
        uint8_t CPOL : 1;
        uint8_t : 2;
        // 专用扩展(无用)
        uint8_t SDBRE : 1;
        // 主机永久拉低片选信号
        uint8_t MCSH : 1;
        uint8_t MSTR : 1;
    };
}SPI_Control2;
#define SPI_CON2_REG ((volatile SPI_Control2*)(SPI_BASE + 2))

typedef union
{
    uint8_t reg;
    struct
    {
        // 预分频SCK = BUS_CLK/(DIVIDER+1)
        // 必须大于等于1
        // 写入会导致SPI重启
        uint8_t DIVIDER : 6;
        uint8_t : 2;
    };
}SPI_ClockPrescale;
#define SPI_CLOCK_PERSCALE_REG ((volatile SPI_ClockPrescale*)(SPI_BASE + 3))

// 每个bit代表一个片选
// 7-1bit可以复用,0bit固定
// 写入会导致SPI重启
#define SPI_CS_REG ((byte_reg_ptr)(SPI_BASE + 4))

#define SPI_TX_DATA_REG ((byte_reg_ptr)(SPI_BASE + 5))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t MDF : 1;
        uint8_t ROE : 1;
        uint8_t : 1;
        uint8_t RRDY : 1;
        uint8_t TRDY : 1;
        uint8_t : 2;
        uint8_t TIP : 1;
    };
}SPI_Status;
#define SPI_STATUS_REG ((const volatile SPI_Status*)(SPI_BASE + 6))

#define SPI_RX_DATA_REG ((ro_byte_reg_ptr)(SPI_BASE + 7))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQMDF : 1;
        uint8_t IRQROE : 1;
        uint8_t : 1;
        uint8_t IRQRRDY : 1;
        uint8_t IRQTRDY : 1;
        uint8_t : 3;
    };
}SPI_InterruptStatus;
// 写1清零
#define SPI_INT_STATUS_REG ((volatile SPI_InterruptStatus*)(SPI_BASE + 8))

typedef union
{
    uint8_t reg;
    struct
    {
        // 模式错误
        uint8_t IRQMDFEN : 1;
        // 接收溢出
        uint8_t IRQROEEN : 1;
        uint8_t : 1;
        // 接收就绪
        uint8_t IRQRRDYEN : 1;
        // 发送就绪
        uint8_t IRQTRDYEN : 1;
        uint8_t : 3;
    };
}SPI_InterruptEnable;
#define SPI_INT_EN_REG ((volatile SPI_InterruptEnable*)(SPI_BASE + 9))



//----------函数定义----------//
uint8_t is_master_mode(void);

void set_master_mode(uint8_t boolean);

uint8_t is_low_active_polarity(void);

void set_low_active_polarity(uint8_t boolean);

uint8_t is_second_clock_phase(void);

void set_second_clock_phase(uint8_t boolean);

uint8_t is_LSB_first(void);

void set_LSB_first(uint8_t boolean);

uint8_t master_transmit_byte_block(uint8_t send_data);


#endif
