#ifndef LEDSD_H
#define LEDSD_H
#include "type.h"
#include "addr_define.h"

#define LEDSD_REG ((byte_reg_ptr)LEDSD_BASE)

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t dp : 2;
        uint8_t dig : 2;
        uint8_t : 4;
    };
}LEDSD_Control;
#define LEDSD_CON_REG ((volatile LEDSD_Control*)LEDSD_BASE+1)

#endif
