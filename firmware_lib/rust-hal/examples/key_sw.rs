#![no_std]
#![no_main]

use riscv_macros::entry;
use xt_rv32i_hal::{
    PacPeripherals,
    lb::{KeySwitch, Ledsd},
    take_pac,
};

#[entry]
fn main() -> ! {
    let Some(PacPeripherals {
        ledsd, keyswitch, ..
    }) = take_pac()
    else {
        loop {}
    };
    let mut ledsd = Ledsd::new(ledsd);
    let key_switch = KeySwitch::new(keyswitch);
    loop {
        let key = key_switch.key();
        let sw = key_switch.switch();
        if bit_is_1(key, 0) {
            ledsd.set_data(0x00);
        } else if bit_is_1(key, 1) {
            ledsd.set_data(0x01);
        } else if bit_is_1(key, 2) {
            ledsd.set_data(0x02);
        } else if bit_is_1(key, 3) {
            ledsd.set_data(0x03);
        } else if bit_is_1(sw, 0) {
            ledsd.set_data(0x10);
        } else if bit_is_1(sw, 1) {
            ledsd.set_data(0x20);
        } else if bit_is_1(sw, 2) {
            ledsd.set_data(0x30);
        }
    }
}

const fn bit_is_1(num: u8, bit: u8) -> bool {
    (num & (1 << bit)) != 0
}
