/*  xtrv32i_wisbone - v0.1 - 适用于XT_RISC-V_MCU的wisbone总线外设库

    - 使用方法: 参照如下代码，在包含头文件前定义`IMPLEMENTATION`实现宏

    #define XTRV32I_WISBONE_IMPLEMENTATION
    #include "xtrv32i_wisbone.h"

|| ===========================================
||
|| 功能配置  在包含头文件前，定义以下宏
||
|| - 禁用部分功能:
||       XTWISBONE_NO_I2C
||       XTWISBONE_NO_SPI
||       XTWISBONE_NO_TIMER
||       XTWISBONE_NO_FLASH
||       XTWISBONE_NO_EBF
||
|| - 仅启用部分功能:
||       XTWISBONE_ONLY_I2C
||       XTWISBONE_ONLY_SPI
||       XTWISBONE_ONLY_TIMER
||       XTWISBONE_ONLY_FLASH
||       XTWISBONE_ONLY_EBF
||
|| ==========================================

*/



#ifdef __EDITOR
#define XTRV32I_WISBONE_IMPLEMENTATION
#include "c/type.h"
#endif

#ifndef INCLUDE_XT_RISCV_MCU_H
#define INCLUDE_XT_RISCV_MCU_H
//////////////   头文件开始   ////////////////////////////////////////
///
//

#if defined(OCCUPY_DOMAIN_3)
#error 重复使用地址域ID
#else
#define OCCUPY_DOMAIN_3
#endif

#ifndef DOMAIN_BASE
#define DOMAIN_BASE(StartID) (0+((StartID)<<(12)))
#endif
#define DOMAIN_WISHBONE_BASE DOMAIN_BASE(3)

// 外设占用地址长度
#define PLL0_LEN 32
#define PLL1_LEN 32
#define I2C_PRIMARY_LEN 10
#define I2C_SECONDARY_LEN 10
#define SPI_LEN 10
#define TIMER_LEN 18
#define FLASH_LEN 6

// 外设地址偏移定义
#define PLL0_OFFSET 0x00
#define PLL1_OFFSET 0x20
#define I2C_PRIMARY_OFFSET 0x40
#define I2C_SECONDARY_OFFSET 0x4A
#define SPI_OFFSET 0x54
#define TIMER_OFFSET 0x5E
#define FLASH_OFFSET 0x70
#define EFB_INT_SOURCE_OFFSET 0x76

#define WISHBONE_BASE(Peripheral)   (DOMAIN_WISHBONE_BASE+Peripheral##_OFFSET)

//
///
//////////////   头文件结束   ////////////////////////////////////////
#endif // INCLUDE_XT_RISCV_MCU_H




#ifdef XTRV32I_WISBONE_IMPLEMENTATION

#if defined(XTWISBONE_ONLY_I2C) || defined(XTWISBONE_ONLY_SPI) || defined(XTWISBONE_ONLY_TIMER) \
 || defined(XTWISBONE_ONLY_FLASH) || defined(XTWISBONE_ONLY_EBF)
#ifndef XTWISBONE_ONLY_I2C
#define XTWISBONE_NO_I2C
#endif
#ifndef XTWISBONE_ONLY_SPI
#define XTWISBONE_NO_SPI
#endif
#ifndef XTWISBONE_ONLY_TIMER
#define XTWISBONE_NO_TIMER
#endif
#ifndef XTWISBONE_ONLY_FLASH
#define XTWISBONE_NO_FLASH
#endif
#ifndef XTWISBONE_ONLY_EBF
#define XTWISBONE_NO_EBF
#endif
#endif


//----------实现开始----------//
#ifndef XTWISBONE_NO_I2C// 🟢实现I2C
#define I2C_PRIMARY_BASE    WISHBONE_BASE(I2C_PRIMARY)
#define I2C_SECONDARY_BASE  WISHBONE_BASE(I2C_SECONDARY)

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

// 写操作会使I2C复位
#define I2C_1_BR0_REG ((byte_reg_ptr)(I2C_PRIMARY_BASE + 2))
// 写操作会使I2C复位
#define I2C_2_BR0_REG ((byte_reg_ptr)(I2C_SECONDARY_BASE + 2))
// BR1的高6位不能读写
// 写操作会使I2C复位
#define I2C_1_BR1_REG ((byte_reg_ptr)(I2C_PRIMARY_BASE + 3))
// BR1的高6位不能读写
// 写操作会使I2C复位
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
        uint8_t IRQHGC : 1;// 收到通用广播
        uint8_t IRQTROE : 1;// 发送/接收溢出或收到NACK
        uint8_t IRQTRRDY : 1;// 发送/接收已准备好
        uint8_t IRQARBL : 1;// 仲裁丢失
        uint8_t : 4;
    };
}I2C_Interrupt;
// 写1清零
#define I2C_1_INT_STATUS_REG ((volatile I2C_Interrupt*)(I2C_PRIMARY_BASE + 8))
#define I2C_2_INT_STATUS_REG ((volatile I2C_Interrupt*)(I2C_SECONDARY_BASE + 8))

#define I2C_1_INT_EN_REG ((volatile I2C_Interrupt*)(I2C_PRIMARY_BASE + 9))
#define I2C_2_INT_EN_REG ((volatile I2C_Interrupt*)(I2C_SECONDARY_BASE + 9))


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
    volatile I2C_Interrupt INT_STATUS_REG;
    volatile I2C_Interrupt INT_EN_REG;
}I2C;
#define I2C_1 ((I2C*)(I2C_PRIMARY_BASE))
#define I2C_2 ((I2C*)(I2C_SECONDARY_BASE))


static uint8_t I2C_DATA_BUFF[8];

/// @brief 设置预分频
/// @warning 重设预分频会使I2C复位
/// @param div 分频公式:SCL = BUS_CLK/(div*4)
/// @param div [1,1023]
static void set_i2c_prescale(I2C* i2c, uint16_t div) {
    div &= 0x3FF;
    i2c->BR0_REG = (uint8_t)div;
    i2c->BR1_REG = (uint8_t)(div >> 8);
}

static uint16_t get_i2c_prescale(I2C* i2c) {
    uint16_t val = i2c->BR0_REG;
    val |= ((uint16_t)i2c->BR1_REG << 8);
    return val;
}

static void reset_i2c(I2C* i2c) {
    i2c->CON_REG.I2CEN = 0;
    DELAY_NOP_10US(5);
    i2c->CON_REG.I2CEN = 1;
}

// FIXME 函数里面的delay只适用于100KHz的I2C速率
// 逆天的技术手册里要求延迟时间与速率周期有关

/// @warning 信号传输不稳定会导致丢失仲裁，从而进入死锁。
static void master_i2c_write_addr_only_block(I2C* i2c, const uint8_t addr) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;// 开始条件+发送
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    i2c->CMD_REG.reg = 0x44;
}

/// @note 未知原因逻辑分析仪得到错误的数据，但是与实物连接又能正常工作，大概率逻辑分析仪的问题。
/// @warning 信号传输不稳定会导致丢失仲裁，从而进入死锁。
static void master_i2c_write_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num) {
    i2c->TX_DATA_REG = addr & 0xFE;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (!i2c->STATUS_REG.TRRDY) {}
        DELAY_NOP_10US(4);
    }
    i2c->CMD_REG.reg = 0x44;
}

/// @warning 信号传输不稳定会导致丢失仲裁，从而进入死锁。
static void master_i2c_read_bytes_block(I2C* i2c, const uint8_t addr, uint8_t* data, const size_t num, const size_t read_num) {
    i2c->TX_DATA_REG = addr;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.TRRDY) {}
    DELAY_NOP_10US(4);
    for (size_t i = 0; i < num; i++) {
        i2c->TX_DATA_REG = data[i];
        i2c->CMD_REG.reg = 0x14;// 发送
        while (!i2c->STATUS_REG.TRRDY) {}
        DELAY_NOP_10US(4);
    }
    i2c->TX_DATA_REG = addr | 0x01;
    i2c->CMD_REG.reg = 0x94;
    while (!i2c->STATUS_REG.SRW) {}
    i2c->CMD_REG.reg = 0x24;
    size_t i = 0;
    for (;i < read_num - 1; i++) {
        while (!i2c->STATUS_REG.TRRDY) {}
        I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    }
    DELAY_NOP_10US(4);
    i2c->CMD_REG.reg = 0x6C;
    while (!i2c->STATUS_REG.TRRDY) {}
    I2C_DATA_BUFF[i] = i2c->RX_DATA_REG;
    // i2c->CMD_REG.reg = 0x04; // 外部存在其他主机时才需要
};

#endif


#ifndef XTWISBONE_NO_SPI// 🟢实现SPI
#define SPI_BASE            WISHBONE_BASE(SPI)
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
        uint8_t IRQMDF : 1;// 模式错误，在主机模式时自身片选被拉低
        uint8_t IRQROE : 1;// 接收溢出
        uint8_t : 1;
        uint8_t IRQRRDY : 1;// 接收就绪
        uint8_t IRQTRDY : 1;// 发送就绪
        uint8_t : 3;
    };
}SPI_Interrupt;
// 写1清零
#define SPI_INT_STATUS_REG ((volatile SPI_Interrupt*)(SPI_BASE + 8))

#define SPI_INT_EN_REG ((volatile SPI_Interrupt*)(SPI_BASE + 9))



static bool is_master_mode(void) { return SPI_CON2_REG->MSTR; }
static void set_master_mode(bool master) { SPI_CON2_REG->MSTR = master; }

static bool is_low_active_polarity(void) { return SPI_CON2_REG->CPOL; }
static void set_low_active_polarity(bool low_active) { SPI_CON2_REG->CPOL = low_active; }

static bool is_second_clock_phase(void) { return SPI_CON2_REG->CPHA; }
static void set_second_clock_phase(bool second_clock) { SPI_CON2_REG->CPHA = second_clock; }

static bool is_LSB_first(void) { return SPI_CON2_REG->LSBF; }
static void set_LSB_first(bool LSB_first) { SPI_CON2_REG->LSBF = LSB_first; }

static uint8_t master_transmit_byte_block(uint8_t send_data) {
    SPI_CON2_REG->reg = 0xC0;
    while (!SPI_STATUS_REG->TRDY) {}
    *SPI_TX_DATA_REG = send_data;
    while (!SPI_STATUS_REG->RRDY) {}
    uint8_t data = *SPI_RX_DATA_REG;
    SPI_CON2_REG->reg = 0x80;
    while (!SPI_STATUS_REG->TIP) {}
    return data;
}
#endif


#ifndef XTWISBONE_NO_TIMER// 🟢实现TIMER
#define TIMER_BASE          WISHBONE_BASE(TIMER)
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
        uint8_t OVF : 1;    // 溢出标志
        uint8_t OCRF : 1;   // 输出匹配标志
        uint8_t ICRF : 1;   // 输入事件标志
        uint8_t BTF : 1;    // 置0标志
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
        uint8_t IRQOVF : 1;     // 溢出
        uint8_t IRQOCRF : 1;    // 输出匹配
        uint8_t IRQICRF : 1;    // 输入事件
        uint8_t : 5;
    };
}TIMER_Interrupt;
// 写1清零
#define TIMER_INT_STATUS_REG ((volatile TIMER_Interrupt*)(TIMER_BASE + 16))
#define TIMER_INT_EN_REG ((volatile TIMER_Interrupt*)(TIMER_BASE + 17))



static void set_top(uint16_t val) {
    *TIMER_SET_TOP_L_REG = val;
    *TIMER_SET_TOP_H_REG = val >> 8;
}

static void set_compare(uint16_t val) {
    *TIMER_SET_COMPARE_L_REG = val;
    *TIMER_SET_COMPARE_H_REG = val >> 8;
}

static uint16_t get_top(void) {
    uint16_t val = 0;
    val = *TIMER_TOP_L_REG;
    val |= *TIMER_TOP_H_REG << 8;
    return val;
}

static uint16_t get_compare(void) {
    uint16_t val = 0;
    val = *TIMER_COMPARE_L_REG;
    val |= *TIMER_COMPARE_H_REG << 8;
    return val;
}

static uint16_t get_counter(void) {
    uint16_t val = 0;
    val = *TIMER_CNT_L_REG;
    val |= *TIMER_CNT_H_REG << 8;
    return val;
}

static uint16_t get_capture(void) {
    return ((uint16_t)*TIMER_CAPTURE_H_REG << 8) | *TIMER_CNT_L_REG;
}

typedef enum {
    DISABLED,
    DIV_1,
    DIV_8,
    DIV_64,
    DIV_256,
    DIV_1024,
}ClkDiv;
/// @brief 设置时钟预分频
/// @param div 分频
static void set_prescale(ClkDiv div) { TIMER_CON0_REG->PRESCALE = div; }

typedef enum { RisingEdge = 0, FallingEdge = 1 }ClkEdge;
/// @brief 设置活动时钟边沿
/// @param edge 边沿
static void set_clkedge(ClkEdge edge) { TIMER_CON0_REG->CLKEDGE = edge; }

typedef enum { CLOCK_TREE = 0, ON_CHIP_OSC = 1 }ClkSel;
/// @brief 选择时钟源
/// @param sel 时钟源
static void set_clksel(ClkSel sel) { TIMER_CON0_REG->CLKSEL = sel; }

typedef enum {
    StaticLow,
    Toggle,
    Set_Clear,
    Clear_Set
}OutputMode;
static void set_output_mode(OutputMode mode) { TIMER_CON1_REG->OCM = mode; }

typedef enum {
    Watchdog,
    ClearTimerOnCompareMatch,
    FastPWM,
    PhaseAndFrequencyCorrectPWM
}TimerMode;
static void set_counter_mode(TimerMode mode) { TIMER_CON1_REG->TCM = mode; }
#endif


#ifndef XTWISBONE_NO_FLASH// 🟢实现FLASH
#define FLASH_BASE          WISHBONE_BASE(FLASH)
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

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t I2CACT : 1;
        uint8_t SSPIACT : 1;
        uint8_t RXFF : 1;
        uint8_t RXFE : 1;
        uint8_t TXFF : 1;
        uint8_t TXFE : 1;
        uint8_t : 1;
        // WB总线到配置(FPGA配置)接口激活(慎用！！！)
        uint8_t WBCACT : 1;
    };
}FlashStatus;
#define FLASH_STATE_REG ((const volatile FlashStatus*)(FLASH_BASE + 2))

#define FLASH_R_DATA_REG ((ro_byte_reg_ptr)(FLASH_BASE + 3))

typedef union
{
    uint8_t reg;
    struct
    {
        uint8_t IRQ_I2CACT : 1;// I2C激活
        uint8_t IRQ_SSPIACT : 1;// SPI激活
        uint8_t IRQ_RXFF : 1;// 接收FIFO已满
        uint8_t IRQ_RXFE : 1;// 接收FIFO已空
        uint8_t IRQ_TXFF : 1;// 发送FIFO已满
        uint8_t IRQ_TXFE : 1;// 发送FIFO已空
        uint8_t : 2;
    };
}FlashInterrupt;
// 写1清零
#define FLASH_INT_STATUS_REG ((volatile FlashInterrupt*)(FLASH_BASE + 4))

#define FLASH_INT_EN_REG ((volatile FlashInterrupt*)(FLASH_BASE + 5))



//=== 命令定义 ===//
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

// 命令与操作数总数量
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
typedef enum { OP_3 = 3, OP_4 = 4 }CMD_OP;

typedef enum { CMD_R = 0, CMD_W = 1 }CMD_RW;

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



//=== 快速命令 ===//
// 实际上NOP指令的操作数可以没有
#define FLASH_NOP FLASH_CON_REG->reg=0x80;\
    *FLASH_W_DATA_REG=ISC_NOOP;\
    FLASH_CON_REG->reg=0x00;


//=== 其他 ===//
#define TOTAL_PAGE 767
#define MAX_PAGE_ADDR 766
#define BUFF_LEN 32
#define PAGE_BYTES 16
#define PAGE_MASK 0x3FFF
static uint8_t DATA_BUFF[BUFF_LEN];
static size_t DATA_LEN;
static uint32_t CMD_OPERANDS_BE;// 命令+操作数(大端序，最高字节是操作数)
#define CMD_OPERANDS_BE_BYTES ((uint8_t*)(&CMD_OPERANDS_BE))
#define SET_CMD_OPERANDS_BE(CMD,OPERANDS) CMD_OPERANDS_BE=((CMD<<24)|OPERANDS);


//=== 函数定义 ===//
static void reset_flash(void) {
    FLASH_CON_REG->reg = 0x40;
    FLASH_CON_REG->reg = 0x00;
}

static uint32_t get_flash_id(void) {
    FLASH_CON_REG->reg = 0x80;
    *FLASH_W_DATA_REG = 0xE0;
    *FLASH_W_DATA_REG = 0x00;
    *FLASH_W_DATA_REG = 0x00;
    *FLASH_W_DATA_REG = 0x00;
    uint8_t buff[4];
    buff[0] = *FLASH_R_DATA_REG;
    buff[1] = *FLASH_R_DATA_REG;
    buff[2] = *FLASH_R_DATA_REG;
    buff[3] = *FLASH_R_DATA_REG;
    FLASH_CON_REG->reg = 0x00;
    return  (buff[0] << 24) | (buff[1] << 16) | (buff[2] << 8) | buff[3];
}

/// @brief 发出命令帧并读取对应数据
/// @param 所有项 用CMD_PARAM宏填充
/// @warning 不可重入，非线程安全
/// @warning 调用前必须用SET_CMD_OPERANDS_BE修改命令与操作数
static void command_frame(const CMD_OP operand_num, const CMD_LEN data_len, const CMD_RW rw) {
    FLASH_CON_REG->reg = 0x80;

    // 写入命令与操作数
    for (size_t i = 0; i < operand_num; i++) {
        *FLASH_W_DATA_REG = CMD_OPERANDS_BE_BYTES[3 - i];
    }

    if (data_len == _XB) {
        uint16_t num_pages = PAGE_MASK & CMD_OPERANDS_BE;
        size_t perfix_dummys = 0;
        size_t postfix_dummys = 0;
        if (num_pages > 1) {
            num_pages--;// 文档要求的-1
            if (CMD_OPERANDS_BE_BYTES[2] == 0x10) {
                perfix_dummys = PAGE_BYTES;
            } else {
                perfix_dummys = 2 * PAGE_BYTES;
                postfix_dummys = 4;
            }
        }
        DATA_LEN = PAGE_BYTES * num_pages;

        // 读取
        // 忽略无用前缀数据
        for (size_t i = 0; i < perfix_dummys; i++) {
            *FLASH_R_DATA_REG;
        }
        // 读取页数据
        for (size_t i = 0, buff_index = 0; i < num_pages; i++) {
            for (size_t i = 0; i < PAGE_BYTES; i++, buff_index++) {
                DATA_BUFF[buff_index] = *FLASH_R_DATA_REG;
            }
            // 忽略尾随无用数据
            for (size_t i = 0; i < postfix_dummys; i++) {
                *FLASH_R_DATA_REG;
            }
        }
    } else if (data_len != NONE) {
        // 固定数据长度读写数据
        DATA_LEN = data_len;
        for (size_t i = 0; i < data_len; i++) {
            if (rw == CMD_R) {
                DATA_BUFF[i] = *FLASH_R_DATA_REG;
            } else {
                *FLASH_W_DATA_REG = DATA_BUFF[i];
            }
        }
    }
    FLASH_CON_REG->reg = 0x00;
}

static void wait_not_busy(void) {
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            return;
        }
    }
}

/// @brief 启用UFM透明传输
static void enable_transparent_UFM(void) {
    SET_CMD_OPERANDS_BE(ISC_ENABLE_X, 0x080000);
    command_frame(CMD_PARAM(ISC_ENABLE_X));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

/// @brief 关闭UFM透明传输
static void disable_transparent_UFM(void) {
    SET_CMD_OPERANDS_BE(ISC_DISABLE, 0);
    command_frame(CMD_PARAM(ISC_DISABLE));
    FLASH_NOP;
}

//// 下面的函数都必须先启用UFM透明传输!!!

/// @brief 设置页地址
/// @param addr 地址
/// @warning 必须先启用UFM透明传输
static void set_UFM_addr(const uint16_t addr) {
    DATA_BUFF[0] = 0x40;DATA_BUFF[1] = 0x00;
    DATA_BUFF[2] = (addr & 0x3FFF) >> 8;DATA_BUFF[3] = addr & 0x3FFF;
    SET_CMD_OPERANDS_BE(LSC_WRITE_ADDRESS, 0);
    command_frame(CMD_PARAM(LSC_WRITE_ADDRESS));
}

/// @brief 重设页地址为0
/// @warning 必须先启用UFM透明传输
static void reset_UFM_addr(void) {
    SET_CMD_OPERANDS_BE(LSC_INIT_ADDR_UFM, 0);
    command_frame(CMD_PARAM(LSC_INIT_ADDR_UFM));
}

/// @brief 指定地址读取一页数据
/// @param addr 地址
/// @warning 必须先启用UFM透明传输
/// @warning 会修改DATA_BUFF
static void read_one_UFM_page(uint16_t addr) {
    if (addr == 0) {
        SET_CMD_OPERANDS_BE(LSC_INIT_ADDR_UFM, 0);
        command_frame(CMD_PARAM(LSC_INIT_ADDR_UFM));
    } else {
        set_UFM_addr(addr);
    }
    // 读取到1页数据
    SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    command_frame(CMD_PARAM(LSC_READ_TAG));
}

/// @brief 指定地址写入一页数据
/// @param addr 地址
/// @param data 数据
/// @warning 必须先启用UFM透明传输
/// @warning 写入前必须确保页被擦除否则无效
static void write_one_UFM_page(const uint16_t addr, uint8_t* data) {
    set_UFM_addr(addr);
    for (size_t i = 0; i < PAGE_BYTES; i++) {
        DATA_BUFF[i] = data[i];
    }
    SET_CMD_OPERANDS_BE(LSC_PROG_TAG, 0x000001);
    command_frame(CMD_PARAM(LSC_PROG_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

/// @brief 从下一个地址读取一页数据
/// @attention Flash硬件 支持地址自增
static void continue_read_one_UFM_page(void) {
    SET_CMD_OPERANDS_BE(LSC_READ_TAG, 0x100001);
    command_frame(CMD_PARAM(LSC_READ_TAG));
}

/// @brief 对下一个地址写入一页数据
/// @attention Flash硬件 支持地址自增
static void continue_write_one_UFM_page(uint8_t* data) {
    for (size_t i = 0; i < PAGE_BYTES; i++) {
        DATA_BUFF[i] = data[i];
    }
    SET_CMD_OPERANDS_BE(LSC_PROG_TAG, 0x000001);
    command_frame(CMD_PARAM(LSC_PROG_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

/// @brief 擦除UFM扇区
/// @warning 必须先启用UFM透明传输
static void erase_UFM(void) {
    SET_CMD_OPERANDS_BE(LSC_ERASE_TAG, 0);
    command_frame(CMD_PARAM(LSC_ERASE_TAG));
    SET_CMD_OPERANDS_BE(LSC_CHECK_BUSY, 0);
    while (1) {
        command_frame(CMD_PARAM(LSC_CHECK_BUSY));
        if (DATA_BUFF[0] == 0) {
            // 轮询直到Busy标志为0
            break;
        }
    }
}

#endif


#ifndef XTWISBONE_NO_EBF// 🟢实现EBF
#define EFB_INT_SOURCE_BASE WISHBONE_BASE(EFB_INT_SOURCE)
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
#endif  // XTRV32I_WISBONE_IMPLEMENTATION
