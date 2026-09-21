#![no_std]
#![no_main]

use riscv_macros::entry;
use xt_rv32i_hal::hb32::Uart;
use xt_rv32i_hal::wisbone::Spi;

#[entry]
fn main() -> ! {
    let mut uart = unsafe { Uart::singleton() };
    let mut spi = unsafe { Spi::singleton() };
    uart.discard_rx_fifo();
    loop {
        let cmd = uart.rx_block();
        if cmd == 0x00 {
            uart.tx_block(spi.control2().into_bits());
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
