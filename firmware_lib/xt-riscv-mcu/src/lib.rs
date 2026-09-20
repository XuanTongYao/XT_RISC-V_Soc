#![no_std]

#[cfg(not(feature = "no_start"))]
core::arch::global_asm!(include_str!("../asm/start.riscv"));
#[cfg(not(feature = "no_bss"))]
core::arch::global_asm!(include_str!("../asm/init_bss.riscv"));
#[cfg(not(feature = "no_trap"))]
core::arch::global_asm!(include_str!("../asm/trap.riscv"));

#[cfg(not(feature = "no_trap"))]
unsafe extern "C" {
    pub unsafe fn UnhandledFault() -> !;
}

// #[inline(never)]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

mod macros;

pub mod hb32;
pub mod lb;
pub mod rv_core;
pub mod wisbone;

pub use rv_core::*;
pub use xt_rv32i_pac;

mod common {

    use xt_rv32i_pac::common::register::RegisterBlock;
    pub struct Peripheral<T> {
        inst: RegisterBlock<T>,
    }

    impl<T> Peripheral<T> {
        #[inline(always)]
        pub const fn from_rb(rb: RegisterBlock<T>) -> Self {
            Self { inst: rb }
        }
        #[inline(always)]
        pub const fn reg(&self) -> &'static T {
            self.inst.regs()
        }
    }
}
