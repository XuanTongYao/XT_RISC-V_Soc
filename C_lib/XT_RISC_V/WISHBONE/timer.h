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
        // 启用外部重置信号
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
        // 启用自动重装载
        uint8_t TSEL : 1;
        // 启用输入捕获
        uint8_t ICEN : 1;
        // 在总线访问下无效
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
        // 暂停计时器
        uint8_t WBPAUSE : 1;
        // 重置计时器(必须等待至少两个周期后手动恢复到0)
        uint8_t WBRESET : 1;
        // 非PWM模式强制输出，当计时器匹配或到达周期时
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
        // 溢出标志
        uint8_t OVF : 1;
        // 输出匹配标志
        uint8_t OCRF : 1;
        // 输入事件标志
        uint8_t ICRF : 1;
        // 置0标志
        uint8_t BTF : 1;
        uint8_t : 4;
    };
}TIMER_Status;
// 对该寄存器执行写入将清空全部位
#define TIMER_STATUS_REG ((volatile TIMER_Status*)(TIMER_BASE + 15))

typedef union
{
    uint8_t reg;
    struct
    {
        // 溢出
        uint8_t IRQOVF : 1;
        // 输出匹配
        uint8_t IRQOCRF : 1;
        // 输入事件
        uint8_t IRQICRF : 1;
        uint8_t : 5;
    };
}TIMER_InterruptStatus;
// 写1清零
#define TIMER_INT_STATUS_REG ((volatile TIMER_InterruptStatus*)(TIMER_BASE + 16))

typedef union
{
    uint8_t reg;
    struct
    {
        // 溢出
        uint8_t IRQOVFEN : 1;
        // 输出匹配
        uint8_t IRQOCRFEN : 1;
        // 输入事件
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

uint16_t get_capture(void);

typedef enum {
    DISABLED = 0x0,
    DIV_1 = 0x1,
    DIV_8 = 0x2,
    DIV_64 = 0x3,
    DIV_256 = 0x4,
    DIV_1024 = 0x5
}ClkDiv;
/// @brief 设置时钟预分频
/// @param div 分频
void set_prescale(ClkDiv div);

typedef enum {
    RisingEdge = 0,
    FallingEdge = 1
}ClkEdge;
/// @brief 设置活动时钟边沿
/// @param edge 边沿
void set_clkedge(ClkEdge edge);

typedef enum {
    CLOCK_TREE = 0,
    ON_CHIP_OSC = 1
}ClkSel;
/// @brief 选择时钟源
/// @param sel 时钟源
void set_clksel(ClkSel sel);

typedef enum {
    StaticLow = 0x0,
    Toggle = 0x1,
    Set_Clear = 0x2,
    Clear_Set = 0x3
}OutputMode;
void set_output_mode(OutputMode mode);

typedef enum {
    Watchdog = 0x0,
    ClearTimerOnCompareMatch = 0x1,
    FastPWM = 0x2,
    PhaseAndFrequencyCorrectPWM = 0x3
}TimerMode;
void set_counter_mode(TimerMode mode);

#endif

