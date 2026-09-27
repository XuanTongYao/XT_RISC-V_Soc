//! 这是一个错误地使用全局变量的示例
//! 说明了为什么不应该滥用static mut

#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::Interrupt::*;
use riscv_macros::entry;
use xt_riscv_mcu::rv_core::{enable_global_interrupt, set_interrupt};
use xt_rv32i_hal::{PacPeripherals, lb::Ledsd, take_pac};

static mut COMPARE: u8 = 0;

/// 因为中断而导致的并发问题\
/// 查看汇编结果可以发现，编译器认为不会有代码修改`COMPARE`
/// ，只读取了一次`COMPARE`，这就是`static mut`的未定义行为\
/// 应该使用原子类型和临界区代替
#[entry]
fn main() -> ! {
    let Some(PacPeripherals { ledsd, .. }) = take_pac() else {
        loop {}
    };
    let mut ledsd = Ledsd::new(ledsd);
    unsafe {
        set_interrupt::<{ 1 << MachineTimer as usize }>();
        enable_global_interrupt();
        loop {
            ledsd.set_data(COMPARE)
        }
    }
}

#[unsafe(no_mangle)]
extern "riscv-interrupt-m" fn mtimer_IRQ_Handler() {
    unsafe { COMPARE += 1 }
}
