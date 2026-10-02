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

#[cfg(not(feature = "no_trap"))]
#[inline(always)]
pub unsafe fn goto_unhandled_fault() -> ! {
    unsafe {
        core::arch::asm!(
            "jal zero, {dst}",
            dst = sym UnhandledFault,
            options(noreturn)
        );
    }
}

pub mod rv_core;
pub use rv_core::*;
