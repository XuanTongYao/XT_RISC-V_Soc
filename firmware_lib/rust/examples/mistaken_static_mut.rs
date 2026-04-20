//! 这是一个错误地使用全局变量的示例
//! 说明了为什么不应该滥用static mut

#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::Interrupt::*;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::LEDSD;
use xt_riscv_mcu::rv_core::{enable_global_interrupt, set_interrupt};

static mut COMPARE: u8 = 0;

/// 因为中断而导致的并发问题\
/// 查看汇编结果可以发现，编译器认为不会有代码修改`COMPARE`
/// ，只读取了一次`COMPARE`，这就是`static mut`的未定义行为\
/// 应该使用原子类型和临界区代替
#[entry]
fn main() -> ! {
    let mut ledsd = LEDSD::SINGLETON;
    unsafe {
        set_interrupt::<{ 1 << MachineTimer as usize }>();
        enable_global_interrupt();
    }
    loop {
        unsafe { ledsd.set_data(COMPARE) }
    }
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn mtimer_IRQ_Handler() {
    unsafe { COMPARE += 1 }
}
