#ifndef ADDR_DEFINE_H
#define ADDR_DEFINE_H

#define DOMAIN_BASE(Domain)         (BUS_DOMAIN_BASE+DOMAIN_##Domain##_OFFSET)
#define HB_BASE(Peripheral)         (DOMAIN_XT_HB_BASE+Peripheral##_OFFSET)
#define WISHBONE_BASE(Peripheral)   (DOMAIN_WISHBONE_BASE+Peripheral##_OFFSET)
#define LB_BASE(Peripheral)         (DOMAIN_XT_LB_BASE+Peripheral##_OFFSET)


//----------内存RAM地址定义----------//
#define INST_RAM_LEN 2048
#define DATA_RAM_LEN 2048
#define INST_RAM_BASE 0
#define DATA_RAM_BASE (INST_RAM_BASE+INST_RAM_LEN)
#define STACK_TOP_ADDR (DATA_RAM_BASE+DATA_RAM_LEN)
// 可执行段与数据段最大长度
#define MAX_TEXT_DATA_LEN (INST_RAM_LEN + DATA_RAM_LEN - 512)



//----------总线地址域划分----------//
// 地址域长度
#define DOMAIN_XT_HB_LEN 32
#define DOMAIN_WISHBONE_LEN 256
#define DOMAIN_XT_LB_LEN 256

// 地址域偏移定义
#define DOMAIN_XT_HB_OFFSET 0
#define DOMAIN_WISHBONE_OFFSET (DOMAIN_XT_HB_OFFSET+DOMAIN_XT_HB_LEN)
#define DOMAIN_XT_LB_OFFSET (DOMAIN_WISHBONE_OFFSET+DOMAIN_WISHBONE_LEN)

// 地址域基地址定义
#define BUS_DOMAIN_BASE         (DATA_RAM_BASE+DATA_RAM_LEN)
#define DOMAIN_XT_HB_BASE       DOMAIN_BASE(XT_HB)
#define DOMAIN_WISHBONE_BASE    DOMAIN_BASE(WISHBONE)
#define DOMAIN_XT_LB_BASE       DOMAIN_BASE(XT_LB)


//----------XT_HB总线本域----------//
// 外设占用地址长度
#define DEBUG_LEN 4
#define EINT_CTRL_LEN 8
#define SYSTEM_TIMER_LEN 16
#define UART_LEN 4

// 外设地址偏移定义
#define DEBUG_OFFSET 0
#define EINT_CTRL_OFFSET (DEBUG_OFFSET+DEBUG_LEN)
#define SYSTEM_TIMER_OFFSET (EINT_CTRL_OFFSET+EINT_CTRL_LEN)
#define UART_OFFSET (SYSTEM_TIMER_OFFSET+SYSTEM_TIMER_LEN)

// 外设基地址定义
#define DEBUG_BASE          HB_BASE(DEBUG)
#define EINT_CTRL_BASE      HB_BASE(EINT_CTRL)
#define SYSTEM_TIMER_BASE   HB_BASE(SYSTEM_TIMER)
#define UART_BASE           HB_BASE(UART)


//----------WISHBONE总线----------//
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

// 外设基地址定义
#define PLL0_BASE           WISHBONE_BASE(PLL0)
#define PLL1_BASE           WISHBONE_BASE(PLL1)
#define I2C_PRIMARY_BASE    WISHBONE_BASE(I2C_PRIMARY)
#define I2C_SECONDARY_BASE  WISHBONE_BASE(I2C_SECONDARY)
#define SPI_BASE            WISHBONE_BASE(SPI)
#define TIMER_BASE          WISHBONE_BASE(TIMER)
#define FLASH_BASE          WISHBONE_BASE(FLASH)
#define EFB_INT_SOURCE_BASE WISHBONE_BASE(EFB_INT_SOURCE)



//----------XT_LB总线----------//
#define KEY_SW_LEN 4
#define GPIO_LEN 8  // 已弃用，地址保留
#define RGB_LEN 8   // 已弃用，地址保留
#define LED_LEN 1
#define LEDSD_LEN 3
#define AF_GPIO_LEN 16

#define KEY_SW_OFFSET 0
#define GPIO_OFFSET (KEY_SW_OFFSET+KEY_SW_LEN)  // 已弃用，地址保留
#define RGB_OFFSET (GPIO_OFFSET+GPIO_LEN)       // 已弃用，地址保留
#define LED_OFFSET (RGB_OFFSET+RGB_LEN)
#define LEDSD_OFFSET (LED_OFFSET+LED_LEN)
#define AF_GPIO_OFFSET (LEDSD_OFFSET+LEDSD_LEN)

#define KEY_SW_BASE     LB_BASE(KEY_SW)
#define GPIO_BASE       LB_BASE(GPIO)   // 已弃用，地址保留
#define RGB_BASE        LB_BASE(RGB)    // 已弃用，地址保留
#define LED_BASE        LB_BASE(LED)
#define LEDSD_BASE      LB_BASE(LEDSD)
#define AF_GPIO_BASE    LB_BASE(AF_GPIO)

#endif
