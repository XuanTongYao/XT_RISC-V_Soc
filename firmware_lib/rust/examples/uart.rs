#![no_std]
#![no_main]

use core::mem::MaybeUninit;

use xt_riscv_mcu::entry;
use xt_riscv_mcu::system_peripheral::Uart;

const TEST_STR: &str = "Hello, world!"; // 这里也会出现C程序的问题，'!'字符打印不出来，怀疑是其他部分

#[entry]
fn main() -> ! {
    let mut uart = Uart::SINGLETON;
    loop {
        let cmd = uart.rx_block();
        if cmd == 0x01 {
            echo_test(&mut uart);
        } else if cmd == 0x02 {
            echo_16byte(&mut uart);
        } else if cmd == 0x03 {
            let x = uart.rx_block();
            spam_0tox_test(&mut uart, x);
        } else if cmd == 0x04 {
            spam_u8_test(&mut uart);
        } else if cmd == 0x05 {
            uart.tx_bytes_block(TEST_STR.as_bytes(), false);
        }
    }
}

fn echo_test(uart: &mut Uart) {
    let byte = uart.rx_block();
    uart.tx_block(byte);
}

fn echo_16byte(uart: &mut Uart) {
    // let tmp = [uart.rx_block(); 16];
    let mut tmp: [MaybeUninit<u8>; 16] = [const { MaybeUninit::uninit() }; 16];
    for byte in &mut tmp {
        let _ = *byte.write(uart.rx_block());
    }
    let tmp = unsafe { tmp.assume_init_mut() };
    uart.tx_bytes_block(tmp, false);
}

fn spam_0tox_test(uart: &mut Uart, x: u8) {
    for i in 0..x {
        uart.tx_block(i);
    }
}

fn spam_u8_test(uart: &mut Uart) {
    for i in 0..256 {
        uart.tx_block(i as u8);
    }
}
