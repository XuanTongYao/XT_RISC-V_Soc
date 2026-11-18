#![no_std]

#[macro_use]
mod macros;

pub mod gpio;
pub mod hb32;
pub mod lb;
pub mod wisbone;

pub use xt_riscv_mcu;
pub use xt_rv32i_pac as pac;

pub type PacPeripherals = pac::xt_rv32i::SubInstancesXtRv32i;

pub fn take_pac() -> Option<PacPeripherals> {
    use core::sync::atomic::{AtomicBool, Ordering::Relaxed};
    static ONCE: AtomicBool = AtomicBool::new(false);
    critical_section::with(|_| {
        if ONCE.load(Relaxed) {
            None
        } else {
            let ret = unsafe { pac::get_top().into_sub_instances() };
            ONCE.store(true, Relaxed);
            Some(ret)
        }
    })
}
