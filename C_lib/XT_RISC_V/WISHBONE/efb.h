#ifndef EFB_H
#define EFB_H
#include "addr_define.h"
#include "type.h"

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t I2C1_INT : 1;
        uint8_t I2C2_INT : 1;
        uint8_t SPI_INT : 1;
        uint8_t TC_INT : 1;
        uint8_t UFMCFG_INT : 1;
        uint8_t : 3;
    };
}EFBInterruptSource;
// 指示EFB中断来源于什么
#define EFB_INT_SOURCE_REG ((volatile EFBInterruptSource*)(EFB_INT_SOURCE_BASE + 1))


#endif
