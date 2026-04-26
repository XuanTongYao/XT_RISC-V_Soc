/*  xtrv32i_lb - v0.1 - 适用于XT_RISC-V_MCU的低速总线外设库

    - 使用方法: 参照如下代码，在包含头文件前定义`IMPLEMENTATION`实现宏

    #define XTRV32I_LB_IMPLEMENTATION
    #include "xtrv32i_lb.h"

|| ===========================================
||
|| 功能配置  在包含头文件前，定义以下宏
||
|| - 禁用部分功能:
||       XTLB_NO_SW_KEY
||       XTLB_NO_AF_GPIO
||       XTLB_NO_LED
||       XTLB_NO_LEDSD
||
|| - 仅启用部分功能:
||       XTLB_ONLY_SW_KEY
||       XTLB_ONLY_AF_GPIO
||       XTLB_ONLY_LED
||       XTLB_ONLY_LEDSD
||
|| ==========================================

*/



#ifdef __EDITOR
#define XTRV32I_LB_IMPLEMENTATION
#include "c/type.h"
#endif

#ifndef INCLUDE_XTRV32I_LB_H
#define INCLUDE_XTRV32I_LB_H
//////////////   头文件开始   ////////////////////////////////////////
///
//

#if defined(OCCUPY_DOMAIN_4)
#error 重复使用地址域ID
#else
#define OCCUPY_DOMAIN_4
#endif

#ifndef DOMAIN_BASE
#define DOMAIN_BASE(StartID) (0+((StartID)<<(12)))
#endif
#define DOMAIN_XT_LB_BASE DOMAIN_BASE(4)

// 每个设备均分地址，字节对齐
#define LB_ADDR_LEN 8
#define LB_ID_LEN 2
#define LB_OFFSET_LEN   (LB_ADDR_LEN-LB_ID_LEN)
#define LB_ID_START_BIT (LB_OFFSET_LEN)

#define LB_BASE(ID)     (DOMAIN_XT_LB_BASE+((ID)<<(LB_ID_START_BIT)))


//
///
//////////////   头文件结束   ////////////////////////////////////////
#endif // INCLUDE_XTRV32I_LB_H




#ifdef XTRV32I_LB_IMPLEMENTATION

#if defined(XTLB_ONLY_SW_KEY) || defined(XTLB_ONLY_AF_GPIO) || defined(XTLB_ONLY_LED) \
 || defined(XTLB_ONLY_LEDSD)
#ifndef XTLB_ONLY_SW_KEY
#define XTLB_NO_SW_KEY
#endif
#ifndef XTLB_ONLY_AF_GPIO
#define XTLB_NO_AF_GPIO
#endif
#ifndef XTLB_ONLY_LED
#define XTLB_NO_LED
#endif
#ifndef XTLB_ONLY_LEDSD
#define XTLB_NO_LEDSD
#endif
#endif


//----------实现开始----------//
#ifndef XTLB_NO_SW_KEY// 🟢实现SW_KEY
#define KEY_SW_BASE     LB_BASE(0)
#define KEY_NUM 4
#define KEY_REG ((half_reg_ptr)(KEY_SW_BASE+0)) // 按下时为高电平(已经在硬件做了翻转)

#define SWITCH_NUM 3
#define SWITCH_REG ((half_reg_ptr)(KEY_SW_BASE+2))
#endif


#ifndef XTLB_NO_AF_GPIO// 🟢实现AF_GPIO
#define AF_GPIO_BASE    LB_BASE(1)
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


#ifndef XTLB_NO_LED// 🟢实现LED
#define LED_BASE        LB_BASE(2)
#define LED_REG ((byte_reg_ptr)LED_BASE)
#endif


#ifndef XTLB_NO_LEDSD// 🟢实现LEDSD
#define LEDSD_BASE      LB_BASE(3)
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
#endif  // XTRV32I_LB_IMPLEMENTATION
