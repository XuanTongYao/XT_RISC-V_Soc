#![no_std]

#[cfg(not(feature = "no_start"))]
core::arch::global_asm!(include_str!("../asm/start.riscv"));
#[cfg(not(feature = "no_bss"))]
core::arch::global_asm!(include_str!("../asm/init_bss.riscv"));
#[cfg(not(feature = "no_trap"))]
core::arch::global_asm!(include_str!("../asm/trap.riscv"));

#[cfg(not(feature = "no_trap"))]
unsafe extern "C" {
    pub unsafe fn AbortHalt() -> !;
}

#[cfg(not(feature = "no_trap"))]
#[inline(always)]
pub unsafe fn goto_abort_halt() -> ! {
    unsafe {
        core::arch::asm!(
            "jal zero, {dst}",
            dst = sym AbortHalt,
            options(noreturn)
        );
    }
}

pub mod rv_core;
pub use rv_core::*;
