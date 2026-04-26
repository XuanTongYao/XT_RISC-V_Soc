/*  xt_riscv_mcu - v0.1 - 适用于XT_RISC-V_MCU的标准库

    - 使用方法: 参照如下代码，在包含头文件前定义`IMPLEMENTATION`实现宏

    #define XT_RISCV_MCU_IMPLEMENTATION
    #include "xt_riscv_mcu.h"

|| ===========================================
||
|| 功能配置  在包含头文件前，定义以下宏
||
|| - 禁用部分功能:
||       XTRISCV_NO_BOOTSTRAP
||       XTRISCV_NO_EINT_CTRL
||       XTRISCV_NO_MTIMER
||       XTRISCV_NO_UART
||
|| - 仅启用部分功能:
||       XTRISCV_ONLY_BOOTSTRAP
||       XTRISCV_ONLY_EINT_CTRL
||       XTRISCV_ONLY_MTIMER
||       XTRISCV_ONLY_UART
||
|| ==========================================

*/



#ifdef __EDITOR
#define XT_RISCV_MCU_IMPLEMENTATION
#include "c/type.h"
#endif

#ifndef INCLUDE_XT_RISCV_MCU_H
#define INCLUDE_XT_RISCV_MCU_H
//////////////   头文件开始   ////////////////////////////////////////
///
//

//----------------类型定义----------------//
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// 指示函数为中断处理函数，以便编译器正确保存并转移上下文
#define IRQ __attribute__((interrupt)) void

typedef volatile uint8_t* byte_reg_ptr;
typedef volatile uint16_t* half_reg_ptr;
typedef volatile uint32_t* word_reg_ptr;
typedef volatile uint64_t* dword_reg_ptr;
typedef const byte_reg_ptr      ro_byte_reg_ptr;
typedef const half_reg_ptr      ro_half_reg_ptr;
typedef const word_reg_ptr      ro_word_reg_ptr;
typedef const dword_reg_ptr     ro_dword_reg_ptr;
typedef byte_reg_ptr            wo_byte_reg_ptr;
typedef half_reg_ptr            wo_half_reg_ptr;
typedef word_reg_ptr            wo_word_reg_ptr;
typedef dword_reg_ptr           wo_dword_reg_ptr;



//----------------内核参数----------------//
#define CORE_FREQ_MHZ   12
#define CORE_FREQ_KHZ   (CORE_FREQ_MHZ*1000)
#define CORE_FREQ_HZ    (CORE_FREQ_MHZ*1000000)

// 使用递减计数**粗略**延时，当`cycles`为奇数时，可能会少一个周期
// 流水线实际循环: `addi->bnez->if_id->id_ex->addi` 循环N次消耗 `(N-1)*4+2` 个周期
#define DELAY(cycles)  do { \
    uint32_t __real_cyc = 1U + ((cycles) / 4U); \
    asm volatile ( \
        "2:\n" \
        "addi %0, %0, -1\n" \
        "bne %0, zero, 2b\n" \
        : "+r" (__real_cyc) \
        : \
        : "memory" \
    ); \
} while(0)
#define DELAY_US(t) DELAY( ((t) * CORE_FREQ_MHZ) )
#define DELAY_MS(t) DELAY( ((t) * CORE_FREQ_KHZ) )
#define DELAY_SEC(t) DELAY( ((t) * CORE_FREQ_HZ) )



//----------------地址映射----------------//
#define BUS_DOMAIN_BASE 0
#define DOMAIN_ID_START_BIT 12
#define DOMAIN_BASE(StartID)        (BUS_DOMAIN_BASE+((StartID)<<(DOMAIN_ID_START_BIT)))
#define SP_BASE(Peripheral)         (DOMAIN_SP_BASE+(Peripheral##_ID<<(SP_ID_START_BIT)))


#if defined(OCCUPY_DOMAIN_0) || defined(OCCUPY_DOMAIN_1) || defined(OCCUPY_DOMAIN_2)
#error 重复使用地址域ID
#else
// 指令RAM
#define OCCUPY_DOMAIN_0
// 数据RAM
#define OCCUPY_DOMAIN_1
// 系统外设
#define OCCUPY_DOMAIN_2
#endif


#define INST_RAM_BASE    DOMAIN_BASE(0)
#define DATA_RAM_BASE    DOMAIN_BASE(1)
#define DOMAIN_SP_BASE   DOMAIN_BASE(2)

#define INST_RAM_LEN (1<<(DOMAIN_ID_START_BIT))
#define DATA_RAM_LEN (1<<(DOMAIN_ID_START_BIT))
#define STACK_TOP_ADDR (DATA_RAM_BASE+DATA_RAM_LEN)
// 可执行段与数据段最大长度
#define MAX_TEXT_DATA_LEN (INST_RAM_LEN + DATA_RAM_LEN - 512)


//----------------系统外设----------------//
// 地址位宽
#define SP_ADDR_LEN 5
#define SP_ID_LEN 3
#define SP_OFFSET_LEN (SP_ADDR_LEN-SP_ID_LEN)
#define SP_ID_START_BIT (SP_OFFSET_LEN+2)
// 外设ID
#define DEBUG_ID 0
#define EINT_CTRL_ID 1
#define SYSTEM_TIMER_ID 2
#define UART_ID 3
#define SOFTWARE_INT_ID 4

// 外设基地址定义
// 这些都是字对齐的

#define SOFTWARE_INT_BASE   SP_BASE(SOFTWARE_INT)

//
///
//////////////   头文件结束   ////////////////////////////////////////
#endif // INCLUDE_XT_RISCV_MCU_H




#ifdef XT_RISCV_MCU_IMPLEMENTATION

#if defined(XTRISCV_ONLY_BOOTSTRAP) || defined(XTRISCV_ONLY_EINT_CTRL) || defined(XTRISCV_ONLY_MTIMER) \
 || defined(XTRISCV_ONLY_UART)
#ifndef XTRISCV_ONLY_BOOTSTRAP
#define XTRISCV_NO_BOOTSTRAP
#endif
#ifndef XTRISCV_ONLY_EINT_CTRL
#define XTRISCV_NO_EINT_CTRL
#endif
#ifndef XTRISCV_ONLY_MTIMER
#define XTRISCV_NO_MTIMER
#endif
#ifndef XTRISCV_ONLY_UART
#define XTRISCV_NO_UART
#endif
#endif


//----------实现开始----------//
#ifndef XTRISCV_NO_BOOTSTRAP// 🟢实现BOOTSTRAP
#define DEBUG_BASE          SP_BASE(DEBUG)
// 读取数据表示启动时状态
#define DOWNLOAD_MODE 0x01
// 向DEBUG_REG写入数据以切换模式
#define INTO_NORMAL_MODE 0xF1
#define DEBUG_REG ((byte_reg_ptr)(DEBUG_BASE))

// 使用自动增地址的硬件实现字符串输出
#define PRELOAD_STR_INIT_ADDR_REG ((wo_byte_reg_ptr)(DEBUG_BASE+4))
#define PRELOAD_STR_AUTO_INC_REG ((ro_byte_reg_ptr)(DEBUG_BASE+8))
#endif


#ifndef XTRISCV_NO_EINT_CTRL// 🟢实现EINT_CTRL
#define EINT_CTRL_BASE      SP_BASE(EINT_CTRL)
#define UART_IRQ_MASK       0x0001

#define I2C1_IRQ_MASK       0x0100
#define I2C2_IRQ_MASK       0x0200
#define SPI_IRQ_MASK        0x0400
#define Timer_IRQ_MASK      0x0800
#define WBC_UFM_IRQ_MASK    0x1000

#define EINT_CTRL_ENABLE_REG ((word_reg_ptr)EINT_CTRL_BASE)
#define EINT_CTRL_PENDING_REG ((ro_word_reg_ptr)(EINT_CTRL_BASE+4))
#endif


#ifndef XTRISCV_NO_MTIMER// 🟢实现MTIMER
#define SYSTEM_TIMER_BASE   SP_BASE(SYSTEM_TIMER)
#define SYSTEM_TIMER_FREQ   1000000
#define SYSTEM_TIMER_MS_CNT (SYSTEM_TIMER_FREQ/1000)
#define SYSTEM_TIMER_US_CNT (SYSTEM_TIMER_FREQ/1000000)

#define _MTIME_REG      ((dword_reg_ptr)SYSTEM_TIMER_BASE)
#define _MTIME_L_REG    ((word_reg_ptr)(SYSTEM_TIMER_BASE+0))
#define _MTIME_H_REG    ((word_reg_ptr)(SYSTEM_TIMER_BASE+4))
#define _MTIMECMP_REG   ((dword_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define _MTIMECMP_L_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+8))
#define _MTIMECMP_H_REG ((word_reg_ptr)(SYSTEM_TIMER_BASE+12))

static void set_mtimecmp(uint64_t val) {
    uint32_t high = (uint32_t)(val >> 32);
    uint32_t low = (uint32_t)val;
    *_MTIMECMP_L_REG = 0xFFFFFFFF;
    *_MTIMECMP_H_REG = high;
    *_MTIMECMP_L_REG = low;
}

static uint64_t get_mtime(void) {
    while (true) {
        uint32_t high = *_MTIME_H_REG;
        uint32_t low = *_MTIME_L_REG;
        if (high == *_MTIME_H_REG) {
            return ((uint64_t)high << 32) | low;
        }
    }
}
#undef _MTIME_REG
#undef _MTIME_L_REG
#undef _MTIME_H_REG
#undef _MTIMECMP_REG
#undef _MTIMECMP_L_REG
#undef _MTIMECMP_H_REG
#endif


#ifndef XTRISCV_NO_UART// 🟢实现UART
#define UART_BASE           SP_BASE(UART)
#define UART_FREQ 19200

#define UART_DATA_REG ((byte_reg_ptr)UART_BASE)

typedef union
{
    uint32_t reg;
    struct
    {
        uint32_t tx_ready : 1;
        uint32_t rx_end : 1;
        uint32_t tx_empty : 1;  // 发送缓冲区空
        uint32_t rx_full : 1;   // 接收缓冲区已满
        uint32_t : 28;
    };
}UART_STATE;
#define UART_STATE_REG ((const volatile UART_STATE*)(UART_BASE + 4))

// #define UART_DEBUG_REG ((byte_reg_ptr)(UART_BASE + 2))

static uint8_t rx_block(void) {
    while (!UART_STATE_REG->rx_end);

    return *UART_DATA_REG;
}


static void tx_block(uint8_t data) {
    while (!UART_STATE_REG->tx_ready);

    *UART_DATA_REG = data;
}

static void tx_bytes_block(uint8_t* data, const size_t num, const bool big_endian) {
    for (size_t i = 0; i < num; i++) {
        uint8_t tmp = big_endian ? data[num - 1 - i] : data[i];
        tx_block(tmp);
    }
}

#endif
#endif  // XT_RISCV_MCU_IMPLEMENTATION
