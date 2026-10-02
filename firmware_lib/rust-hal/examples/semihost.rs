#![no_std]
#![no_main]

use riscv_macros::entry;
use semihosting::println;
use semihosting::sys::arm_compat::sys_write0;
use xt_rv32i_hal as _;

const HELLO: &core::ffi::CStr = c"semihosting: Hello, world!\n";

#[entry]
fn main() -> ! {
    sys_write0(HELLO);
    let mut time = 0;
    loop {
        println!("Heartbeat: {}", time);
        xt_riscv_mcu::delay_sec(1);
        time += 1;
    }
}
