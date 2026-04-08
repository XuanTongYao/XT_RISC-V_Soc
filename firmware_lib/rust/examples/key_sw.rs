#![no_std]
#![no_main]

use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::{KeySwitch, LEDSD};

#[entry]
fn main() -> ! {
    let mut ledsd = LEDSD::SINGLETON;
    let key_switch = KeySwitch::SINGLETON;
    loop {
        let key = key_switch.key();
        let sw = key_switch.switch();
        if bit_is_1(key, 0) {
            ledsd.display(0x00);
        } else if bit_is_1(key, 1) {
            ledsd.display(0x01);
        } else if bit_is_1(key, 2) {
            ledsd.display(0x02);
        } else if bit_is_1(key, 3) {
            ledsd.display(0x03);
        } else if bit_is_1(sw, 0) {
            ledsd.display(0x10);
        } else if bit_is_1(sw, 1) {
            ledsd.display(0x20);
        } else if bit_is_1(sw, 2) {
            ledsd.display(0x30);
        }
    }
}

const fn bit_is_1(num: u16, bit: u8) -> bool {
    (num & (1 << bit)) != 0
}
