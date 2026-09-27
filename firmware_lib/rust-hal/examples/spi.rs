#![no_std]
#![no_main]

use embedded_hal::spi::{MODE_0, MODE_1, MODE_2, MODE_3};
use riscv_macros::entry;
use xt_rv32i_hal::hb32::Uart;
use xt_rv32i_hal::wisbone::{Master, Spi};
use xt_rv32i_hal::{PacPeripherals, take_pac};

#[entry]
fn main() -> ! {
    let Some(PacPeripherals { spi, uart, .. }) = take_pac() else {
        loop {}
    };
    let mut uart = Uart::new(uart);
    let mut spi = Spi::<Master>::init(spi, 0, MODE_0, false);
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
                0x03 => spi.set_mode(MODE_0, set),
                0x04 => spi.set_mode(MODE_1, set),
                0x05 => spi.set_mode(MODE_2, set),
                0x06 => spi.set_mode(MODE_3, set),
                0x07 => spi.set_prescale(data.into()).unwrap(),
                0x08 => spi.set_cs(data),
                _ => unreachable!(),
            }
        } else if cmd < 0x0B {
            let data = uart.rx_block();
            let rx = match cmd {
                0x09 => spi.try_start_rw_block(data).unwrap_or(0),
                0x0A => spi.try_rw_byte_block(data).unwrap_or(0),
                _ => unreachable!(),
            };
            uart.tx_block(rx);
        } else if cmd == 0x0B {
            let _ = spi.try_finish_rw_block();
        }
    }
}
