#![no_std]
#![no_main]

use xt_riscv_mcu::entry;
use xt_riscv_mcu::system_peripheral::Uart;
use xt_riscv_mcu::wisbone::SPI;

#[entry]
fn main() -> ! {
    let mut uart = Uart::SINGLETON;
    let mut spi = SPI::SINGLETON;
    uart.discard_rx_fifo();
    loop {
        let cmd = uart.rx_block();
        if cmd == 0x00 {
            uart.tx_block(spi.reg().control2.read().into());
        } else if cmd == 0x01 {
            uart.tx_block(spi.prescale());
        } else if cmd == 0x02 {
            uart.tx_block(spi.cs());
        } else if cmd < 0x09 {
            let data = uart.rx_block();
            let set = data != 0;
            match cmd {
                0x03 => spi.set_master_mode(set),
                0x04 => spi.set_polarity_active_low(set),
                0x05 => spi.set_phase_second_edge(set),
                0x06 => spi.set_lsb_first(set),
                0x07 => spi.set_prescale(data),
                0x08 => spi.set_cs(data),
                _ => unreachable!(),
            }
        } else if cmd < 0x0B {
            let data = uart.rx_block();
            let rx = match cmd {
                0x09 => spi.master_start_rw_block(data),
                0x0A => spi.master_rw_byte_block(data),
                _ => unreachable!(),
            };
            uart.tx_block(rx);
        } else if cmd == 0x0B {
            spi.master_finish_rw_block();
        }
    }
}
