#![no_std]

mod macros;

pub mod hb32;
pub mod lb;
pub mod wisbone;

pub use xt_riscv_mcu;
pub use xt_rv32i_pac as pac;

#[cfg(feature = "panic_halt")]
#[inline(never)]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
