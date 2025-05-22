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

uint8_t set_low_active_polarity(uint8_t boolean) {
    SPI_CON2_REG->CPOL = boolean;
}

uint8_t is_second_clock_phase(void) {
    return SPI_CON2_REG->CPHA;
}

uint8_t set_second_clock_phase(uint8_t boolean) {
    SPI_CON2_REG->CPHA = boolean;
}










