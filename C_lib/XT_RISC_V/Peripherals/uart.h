#ifndef UART_H
#define UART_H
#include "type.h"
#include "addr_define.h"

#define UART_FREQ 19200

#define UART_DATA_REG ((byte_reg_ptr)UART_BASE)

typedef struct
{
    uint32_t tx_ready : 1;
    uint32_t rx_end : 1;
    uint32_t rx_fifo_empty : 1;
    uint32_t rx_fifo_full : 1;
    uint32_t : 28;
}UART_STATE;
#define UART_STATE_REG ((const volatile UART_STATE*)(UART_BASE + 4))

// #define UART_DEBUG_REG ((byte_reg_ptr)(UART_BASE + 2))

uint8_t rx_block(void);
void tx_block(uint8_t data);
void tx_bytes_block(uint8_t* data, const size_t num, const uint8_t big_endian);

#endif
