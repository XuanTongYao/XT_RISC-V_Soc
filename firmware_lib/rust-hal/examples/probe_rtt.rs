#![no_std]
#![no_main]

use defmt_rtt as _;
use riscv_macros::entry;
use xt_rv32i_hal as _;

#[entry]
fn main() -> ! {
    defmt::info!("defmt: Hello, world!");
    let mut time = 0;
    loop {
        defmt::info!("Heartbeat: {=u32}", time);
        xt_riscv_mcu::delay_sec(1);
        time += 1;
    }
}
