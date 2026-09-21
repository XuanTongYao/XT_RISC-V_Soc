//! Note
//! 在编译产物中 `mtimer_IRQ_Handler` 疑似保存了从未被使用的寄存器？
//! In the compiled output, `mtimer_IRQ_Handler` retains a register that has never been used

#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::Interrupt::*;
use riscv_macros::entry;
use xt_riscv_mcu::{ExternalInterrupt, enable_global_interrupt, set_interrupt};
use xt_rv32i_hal::hb32::{EintController, Mtime, Uart};
use xt_rv32i_hal::lb::{Led, Ledsd};

#[entry]
fn main() -> ! {
    let mut eint = unsafe { EintController::singleton() };
    unsafe {
        eint.set_enable(ExternalInterrupt::Uart.into_mask().into());
        set_interrupt::<{ (1 << MachineExternal as usize) | (1 << MachineTimer as usize) }>();
        let mut mtime = Mtime::singleton();
        mtime.update_mtimecmp_forward(Mtime::sec_ticks(1));
        enable_global_interrupt();
    }
    loop {}
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn UART_RX_IRQ_Handler() {
    let mut ledsd = unsafe { Ledsd::singleton() };
    let mut uart = unsafe { Uart::singleton() };
    ledsd.set_data(uart.rx_forced());
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn mtimer_IRQ_Handler() {
    static mut TIMER: u32 = 0;
    let mut mtime = unsafe { Mtime::singleton() };
    mtime.update_mtimecmp_forward(Mtime::sec_ticks(1));
    let mut ledsd = unsafe { Ledsd::singleton() };
    let mut led = unsafe { Led::singleton() };
    unsafe {
        let tmp = TIMER + 1;
        TIMER = tmp;
        ledsd.set_data(tmp as u8);
        led.set_data(tmp as u8);
    }
}
