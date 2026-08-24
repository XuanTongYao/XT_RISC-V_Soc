#![no_std]

#[cfg(not(feature = "no_start"))]
core::arch::global_asm!(include_str!("../asm/start.riscv"));
#[cfg(not(feature = "no_bss"))]
core::arch::global_asm!(include_str!("../asm/init_bss.riscv"));
#[cfg(not(feature = "no_trap"))]
core::arch::global_asm!(include_str!("../asm/trap.riscv"));

#[cfg(not(feature = "no_trap"))]
unsafe extern "C" {
    pub unsafe fn UnhandledFault();
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

mod common {

    pub struct Peripheral<T, const BASE: usize> {
        ptr: *mut T,
    }

    impl<T, const BASE: usize> Peripheral<T, BASE> {
        pub(crate) const BASE: usize = BASE;
        #[inline(always)]
        pub const unsafe fn from_ptr(ptr: *mut ()) -> Self {
            Self { ptr: ptr as _ }
        }
        #[inline(always)]
        pub const fn as_ptr(&self) -> *mut () {
            self.ptr as _
        }
        #[inline(always)]
        pub const fn reg(&self) -> &T {
            unsafe { &*self.ptr }
        }
    }

    const BUS_DOMAIN_BASE: usize = 0;
    const DOMAIN_ID_START_BIT: usize = 12;
    pub const fn domain_base(statr_id: usize) -> usize {
        BUS_DOMAIN_BASE + (statr_id << DOMAIN_ID_START_BIT)
    }
}
