#![no_std]
#![no_main]

use core::num::NonZeroU16;

use embedded_hal::i2c::I2c as _;
use riscv_macros::entry;
use xt_rv32i_hal::hb32::Uart;
use xt_rv32i_hal::wisbone::{I2c, Master};
use xt_rv32i_hal::{PacPeripherals, take_pac};

const SSD1306_ADDR: u8 = 0x3C; // 右对齐的地址

const DISPLAY_ON_AND_HORIZONTAL_ADDRESSING: [u8; 8] =
    [0x00, 0xA1, 0xC8, 0x8D, 0x14, 0xAF, 0x20, 0x00];
const DISPLAY_OFF: [u8; 4] = [0x00, 0xAE, 0x8D, 0x10];
const GDDRAM_ON: [u8; 2] = [0x80, 0xA4];
const GDDRAM_OFF: [u8; 2] = [0x80, 0xA5];
const HORIZONTAL_SCROLL_PAGE0_ON: [u8; 9] = [0x00, 0x26, 0x00, 0x00, 0x07, 0x00, 0x00, 0xff, 0x2f];
const HORIZONTAL_SCROLL_OFF: [u8; 2] = [0x80, 0x2E];
const DATA_1234: [u8; 21] = [
    0x40, 0x00, 0x08, 0xFC, 0x00, 0x00, 0xC4, 0xA4, 0x9C, 0x00, 0x94, 0x9C, 0xE4, 0x20, 0x50, 0x48,
    0xFC, 0x00, 0x9C, 0x94, 0xF4,
];

// SSD1306 128x64显示屏
// 00和40开头的序列是连续数据/命令，发送后要结束传输。 才能再发送其他功能序列
// 显示屏在I2C模式下并不具备读取功能

#[entry]
fn main() -> ! {
    let Some(PacPeripherals { uart, i2c1, .. }) = take_pac() else {
        loop {}
    };
    let mut uart = Uart::new(uart);
    let mut i2c = unsafe { I2c::<Master>::init_unchecked(i2c1, 30) };
    uart.discard_rx_fifo();
    loop {
        let cmd = uart.rx_block();
        match cmd {
            // 单元功能
            // 0x00 => i2c.set_general_call(uart.rx_block() != 0),
            // 0x01 => i2c.set_sda_output_delay(uart.rx_block()),
            0x02 => {
                let low = uart.rx_block() as u16;
                i2c.set_prescale(unsafe {
                    NonZeroU16::new_unchecked((uart.rx_block() as u16) << 8 | low)
                })
                .unwrap();
            }
            0x03 => i2c.reset(),
            // 0x04 => uart.tx_block(i2c.read_byte_block()),
            // 0x05 => uart.tx_block(i2c.finish_read_block()),
            // SSD1306功能，请先开启传输
            // 0x06 => i2c.write(SSD1306_ADDR, &DISPLAY_ON_AND_HORIZONTAL_ADDRESSING),
            0x07 => i2c
                .write(SSD1306_ADDR, &DISPLAY_ON_AND_HORIZONTAL_ADDRESSING)
                .unwrap(),
            0x08 => i2c.write(SSD1306_ADDR, &DISPLAY_OFF).unwrap(),
            0x09 => i2c.write(SSD1306_ADDR, &GDDRAM_ON).unwrap(),
            0x0a => i2c.write(SSD1306_ADDR, &GDDRAM_OFF).unwrap(),
            0x0b => i2c
                .write(SSD1306_ADDR, &HORIZONTAL_SCROLL_PAGE0_ON)
                .unwrap(),
            0x0c => i2c.write(SSD1306_ADDR, &HORIZONTAL_SCROLL_OFF).unwrap(),
            0x0d => {
                use embedded_hal::i2c::Operation::*;
                // 全屏刷新，可以写00来清屏或写ff来全亮
                let byte = uart.rx_block();
                // 全屏有128 * 64 / 8 字节的数据
                let buffer = [byte; 32];
                let cmd = [0x40];
                let mut operations: [embedded_hal::i2c::Operation<'_>; 33] =
                    core::array::from_fn(|i| if i == 0 { Write(&cmd) } else { Write(&buffer) });
                i2c.transaction(SSD1306_ADDR, &mut operations).unwrap();
            }
            0x0e => i2c.write(SSD1306_ADDR, &DATA_1234).unwrap(),
            // 0x0f => i2c.master_write_block(&HORIZONTAL_SCROLL_OFF),
            // 查询状态
            0x20 => uart.tx_block(i2c.status().into_bits()),
            0x21 => uart.tx_block(i2c.int_status().into_bits()),
            0x22 => uart.tx_block(i2c.int_en().into_bits()),
            0x23 => uart.tx_block(i2c.general_call_data()),
            0x24 => uart.tx_bytes_block(&i2c.prescale().to_le_bytes(), false),
            _ => (),
        }
    }
}
