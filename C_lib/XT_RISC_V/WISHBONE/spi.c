#include "spi.h"


uint8_t is_master_mode(void) {
    return SPI_CON2_REG->MSTR;
}

void set_master_mode(uint8_t boolean) {
    SPI_CON2_REG->MSTR = boolean;
}

uint8_t is_low_active_polarity(void) {
    return SPI_CON2_REG->CPOL;
}

void set_low_active_polarity(uint8_t boolean) {
    SPI_CON2_REG->CPOL = boolean;
}

uint8_t is_second_clock_phase(void) {
    return SPI_CON2_REG->CPHA;
}

void set_second_clock_phase(uint8_t boolean) {
    SPI_CON2_REG->CPHA = boolean;
}

uint8_t is_LSB_first(void) {
    return SPI_CON2_REG->LSBF;
}

void set_LSB_first(uint8_t boolean) {
    SPI_CON2_REG->LSBF = boolean;
}

uint8_t master_transmit_byte_block(uint8_t send_data) {
    SPI_CON2_REG->reg = 0xC0;
    while (!SPI_STATUS_REG->TRDY) {}
    *SPI_TX_DATA_REG = send_data;
    while (!SPI_STATUS_REG->RRDY) {}
    uint8_t data = *SPI_RX_DATA_REG;
    SPI_CON2_REG->reg = 0x80;
    while (!SPI_STATUS_REG->TIP) {}
    return data;
}










