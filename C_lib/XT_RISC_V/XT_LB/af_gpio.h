#ifndef AF_GPIO_H
#define AF_GPIO_H
#include "type.h"
#include "addr_define.h"

#define AF_GPIO_NUM 32
#define __IN_AF_EN(AF_ID) (AF_GPIO->IN_AF_CON_REG.enable_##AF_ID)
#define __IN_AF_SEL(AF_ID) (AF_GPIO->IN_AF_CON_REG.gpio_sel_##AF_ID)
#define __OUT_AF_EN(AF_ID) (AF_GPIO->OUT_AF_CON_REG.enable_##AF_ID)
#define __OUT_AF_SEL(AF_ID) (AF_GPIO->OUT_AF_CON_REG.gpio_sel_##AF_ID)
#define IN_AF_EN(AF_ID) __IN_AF_EN(AF_ID)
#define IN_AF_SEL(AF_ID) __IN_AF_SEL(AF_ID)
#define OUT_AF_EN(AF_ID) __OUT_AF_EN(AF_ID)
#define OUT_AF_SEL(AF_ID) __OUT_AF_SEL(AF_ID)

typedef union
{
    uint32_t reg;
    struct
    {
        uint32_t gpio_sel_0 : 3;
        uint32_t enable_0 : 1;
        uint32_t gpio_sel_1 : 3;
        uint32_t enable_1 : 1;
        uint32_t gpio_sel_2 : 3;
        uint32_t enable_2 : 1;
        uint32_t gpio_sel_3 : 3;
        uint32_t enable_3 : 1;
        uint32_t gpio_sel_4 : 3;
        uint32_t enable_4 : 1;
        uint32_t gpio_sel_5 : 3;
        uint32_t enable_5 : 1;
        uint32_t gpio_sel_6 : 3;
        uint32_t enable_6 : 1;
        uint32_t gpio_sel_7 : 3;
        uint32_t enable_7 : 1;
    };
}FUNCT_AF_Control;


typedef struct
{
    volatile uint32_t DIRECTION_REG;
    volatile uint32_t DATA_REG;
    volatile FUNCT_AF_Control IN_AF_CON_REG;
    volatile FUNCT_AF_Control OUT_AF_CON_REG;
}AF_GPIO_CON;
#define AF_GPIO ((AF_GPIO_CON*)(AF_GPIO_BASE))

// GPIO[31:29] 对应RGB2
// GPIO[28:26] 对应RGB1


// 输入复用定义
#define AF_ID_TIMER_RST 0
#define AF_ID_TIMER_INPUT 1

// 输出复用定义
// !!!严禁多个输出功能同时复用一个GPIO
// ID低的优先级更高
#define AF_ID_TIMER_OUTPUT 0
#define AF_ID_SPI_CS2 1


#endif
