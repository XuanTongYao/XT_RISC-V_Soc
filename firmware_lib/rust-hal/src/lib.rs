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

pub type PacPeripherals = pac::xt_rv32i::SubInstancesXtRv32i;

pub fn take_pac() -> Option<PacPeripherals> {
    use core::sync::atomic::{AtomicBool, Ordering::Relaxed};
    static ONCE: AtomicBool = AtomicBool::new(false);
    if ONCE.load(Relaxed) {
        return None;
    }
    ONCE.store(true, Relaxed);
    Some(unsafe { pac::get_top().into_sub_instances() })
}

// 可以为每个外设都提供一个单次获取方法，可以减少一点点开销
// 用AtomicU32多个位来存储获取状态如何？节省多个bit
