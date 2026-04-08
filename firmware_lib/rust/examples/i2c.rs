#![no_std]
#![no_main]

use xt_riscv_mcu::entry;
use xt_riscv_mcu::system_peripheral::Uart;
use xt_riscv_mcu::wisbone::I2C;

const SSD1306_ADDR: u8 = 0x78;

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
    let mut uart = Uart::SINGLETON;
    let mut i2c = I2C::new_primary();
    uart.discard_rx_fifo();
    loop {
        let cmd = uart.rx_block();
        match cmd {
            // 单元功能
            0x00 => i2c.master_start_transmission_block(uart.rx_block()),
            0x01 => i2c.master_write_byte_block(uart.rx_block()),
            0x02 => i2c.master_finish_write(),
            0x03 => i2c.master_into_read_block(uart.rx_block()),
            0x04 => uart.tx_block(i2c.master_read_byte_block()),
            0x05 => uart.tx_block(i2c.master_finish_read_block()),
            // SSD1306功能，请先开启传输
            0x06 => i2c.master_start_transmission_block(SSD1306_ADDR),
            0x07 => i2c.master_write_block(&DISPLAY_ON_AND_HORIZONTAL_ADDRESSING), // 发送后要结束传输，才能发送其他功能序列
            0x08 => i2c.master_write_block(&DISPLAY_OFF), // 发送后要结束传输，才能发送其他功能序列
            0x09 => i2c.master_write_block(&GDDRAM_ON),
            0x0a => i2c.master_write_block(&GDDRAM_OFF),
            0x0b => i2c.master_write_block(&HORIZONTAL_SCROLL_PAGE0_ON), // 发送后要结束传输，才能发送其他功能序列
            0x0c => i2c.master_write_block(&HORIZONTAL_SCROLL_OFF),
            0x0d => {
                // 全屏刷新，可以写00来清屏或写ff来全亮
                // 发送后要结束传输，才能发送其他功能序列
                let byte = uart.rx_block();
                i2c.master_write_byte_block(0x40);
                for _ in 0..(128 * 64 / 8) {
                    i2c.master_write_byte_block(byte);
                }
            }
            0x0e => i2c.master_write_block(&DATA_1234), // 显示1234 发送后要结束传输，才能发送其他功能序列
            // 0x0f => i2c.master_write_block(&HORIZONTAL_SCROLL_OFF),
            // 查询状态
            0x20 => uart.tx_block(i2c.inner.status().into_bits()),
            0x21 => uart.tx_block(i2c.inner.int_status().into_bits()),
            0x22 => uart.tx_block(i2c.inner.int_en().into_bits()),
            _ => (),
        }
    }
}
