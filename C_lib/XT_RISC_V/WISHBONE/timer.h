#ifndef TIMER_H
#define TIMER_H
#include "type.h"
#include "addr_define.h"


//----------寄存器定义----------//
typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t : 1;
        uint8_t CLKSEL : 1;
        uint8_t CLKEDGE : 1;
        uint8_t PRESCALE : 3;
        uint8_t : 1;
        uint8_t RSTEN : 1;
    };
}TIMER_Control0;
#define TIMER_CON0_REG ((volatile TIMER_Control0*)(TIMER_BASE + 0))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t TCM : 2;
        uint8_t OCM : 2;
        uint8_t TSEL : 1;
        uint8_t ICEN : 1;
        uint8_t SOVFEN : 1;
        uint8_t : 1;
    };
}TIMER_Control1;
#define TIMER_CON1_REG ((volatile TIMER_Control1*)(TIMER_BASE + 1))

// 写入的是影子寄存器
#define TIMER_SET_TOP_L_REG ((wo_byte_reg_ptr)(TIMER_BASE + 2))
#define TIMER_SET_TOP_H_REG ((wo_byte_reg_ptr)(TIMER_BASE + 3))

// 写入的是影子寄存器
#define TIMER_SET_COMPARE_L_REG ((wo_byte_reg_ptr)(TIMER_BASE + 4))
#define TIMER_SET_COMPARE_H_REG ((wo_byte_reg_ptr)(TIMER_BASE + 5))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t WBPAUSE : 1;
        uint8_t WBRESET : 1;
        uint8_t WBFORCE : 1;
        uint8_t : 5;
    };
}TIMER_Control2;
#define TIMER_CON2_REG ((volatile TIMER_Control2*)(TIMER_BASE + 6))

#define TIMER_CNT_L_REG ((ro_byte_reg_ptr)(TIMER_BASE + 7))
#define TIMER_CNT_H_REG ((ro_byte_reg_ptr)(TIMER_BASE + 8))

#define TIMER_TOP_L_REG ((ro_byte_reg_ptr)(TIMER_BASE + 9))
#define TIMER_TOP_H_REG ((ro_byte_reg_ptr)(TIMER_BASE + 10))

#define TIMER_COMPARE_L_REG ((ro_byte_reg_ptr)(TIMER_BASE + 11))
#define TIMER_COMPARE_H_REG ((ro_byte_reg_ptr)(TIMER_BASE + 12))

#define TIMER_CAPTURE_L_REG ((ro_byte_reg_ptr)(TIMER_BASE + 13))
#define TIMER_CAPTURE_H_REG ((ro_byte_reg_ptr)(TIMER_BASE + 14))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t OVF : 1;
        uint8_t OCRF : 1;
        uint8_t ICRF : 1;
        uint8_t BTF : 1;
        uint8_t : 4;
    };
}TIMER_Status;
#define TIMER_STATUS_REG ((volatile TIMER_Status*)(TIMER_BASE + 15))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQOVF : 1;
        uint8_t IRQOCRF : 1;
        uint8_t IRQICRF : 1;
        uint8_t : 5;
    };
}TIMER_InterruptStatus;
#define TIMER_INT_STATUS_REG ((volatile TIMER_InterruptStatus*)(TIMER_BASE + 16))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQOVFEN : 1;
        uint8_t IRQOCRFEN : 1;
        uint8_t IRQICRFEN : 1;
        uint8_t : 5;
    };
}TIMER_InterruptEnable;
#define TIMER_INT_EN_REG ((volatile TIMER_InterruptEnable*)(TIMER_BASE + 17))


//----------函数定义----------//

void set_top(uint16_t val);

void set_compare(uint16_t val);

uint16_t get_top(void);

uint16_t get_compare(void);

uint16_t get_counter(void);


#endif

