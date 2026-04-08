#![no_std]

#[cfg(all(
    feature = "start_asm",
    not(feature = "bare_start"),
    not(feature = "no_trap_start")
))]
core::arch::global_asm!(include_str!("../asm/start.riscv"));
#[cfg(feature = "no_trap_start")]
core::arch::global_asm!(include_str!("../asm/no_trap_start.riscv"));
#[cfg(feature = "bare_start")]
core::arch::global_asm!(include_str!("../asm/bare_start.riscv"));

#[cfg(all(feature = "no_trap_start", feature = "bare_start"))]
compile_error!(
    r#"Error: Multiple start assembly files cannot be enabled at the same time
    错误: 不允许同时启用多种start汇编文件"#
);

// #[inline(never)]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

mod macros;

pub mod lb;
pub mod rv_core;
pub mod system_peripheral;
pub mod wisbone;

pub use xt_riscv_mcu_macros::entry;

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
