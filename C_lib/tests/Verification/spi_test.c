#include "XT_RISC_V_Base.h"
#include "spi.h"
#include "uart.h"

void main(void) {
    ENABLE_MEI;
    *EINT_CTRL_ENABLE_REG = UART_IRQ_MASK;
    ENABLE_GLOBAL_MINT;
    while (1) {
        NOP;
    }
}

// const char tip[] = "rx_data";

IRQ UART_RX_IRQ_Handler(void) {
    uint8_t val = *UART_DATA_REG;
    if (val == 0x01) {
        tx_block(SPI_CON2_REG->reg);
    } else if (val >= 0x02 && val <= 0x07) {
        uint8_t data = rx_block();
        if (val == 0x02) {
            set_master_mode(data);
        } else if (val == 0x03) {
            set_low_active_polarity(data);
        } else if (val == 0x04) {
            set_second_clock_phase(data);
        } else if (val == 0x05) {
            set_LSB_first(data);
        } else if (val == 0x06) {
            uint8_t rx_data = master_transmit_byte_block(data);
            // tx_bytes_block((uint8_t*)tip, 7, 0);
            tx_block(rx_data);
        } else if (val == 0x07) {
            SPI_CLOCK_PERSCALE_REG->DIVIDER = data;
        }
    } else if (val == 0x08) {
        tx_block(is_master_mode());
        tx_block(is_low_active_polarity());
        tx_block(is_second_clock_phase());
        tx_block(is_LSB_first());
        tx_block(*SPI_CS_REG);
    }

}



