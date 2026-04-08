#![no_std]
#![no_main]

use xt_riscv_mcu::entry;
use xt_riscv_mcu::system_peripheral::Uart;
use xt_riscv_mcu::wisbone::Flash;

const TEST_DATA: [u8; 16] = arr_range::<16>();
const DELIMITER: [u8; 2] = [0xF0, 0x0F];

#[entry]
fn main() -> ! {
    let mut buffer = [0u8; 16];
    let mut uart = Uart::SINGLETON;
    let mut flash = Flash::SINGLETON;
    flash.reset();
    flash.enable_transparent_ufm();
    uart.discard_rx_fifo();
    loop {
        uart.tx_bytes_block(&DELIMITER, false);
        let cmd = uart.rx_block();
        match cmd {
            // 两种读取id的方式
            0x00 => uart.tx_bytes_block(&flash.flash_id().to_be_bytes(), false),
            0x01 => {
                flash.command_frame_read(Flash::IDCODE_PUB, 0, &mut buffer[0..4]);
                uart.tx_bytes_block(&buffer[0..4], false);
            }
            0x02 => {
                flash.read_one_ufm_page(&mut buffer);
                uart.tx_bytes_block(&buffer, false);
            }
            0x03 => flash.write_one_ufm_page(&TEST_DATA),
            0x04 => flash.reset_ufm_addr(),
            0x05 => {
                let mut addr = (uart.rx_block() as u16) << 8;
                addr |= uart.rx_block() as u16;
                flash.set_ufm_addr(addr);
            }
            0x06 => flash.erase_ufm(),
            0x07 => flash.enable_transparent_ufm(),
            0x08 => flash.disable_transparent_ufm(),
            _ => (),
        }
    }
}

const fn arr_range<const N: usize>() -> [u8; N] {
    let mut arr = [0u8; N];
    let mut i = 0;
    while i < N {
        arr[i] = i as u8;
        i += 1;
    }
    arr
}
