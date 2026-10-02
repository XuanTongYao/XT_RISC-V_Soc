#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use core::sync::atomic::AtomicBool;
use core::sync::atomic::Ordering::Relaxed;

use riscv::interrupt::Interrupt::*;
use riscv_macros::entry;
use xt_riscv_mcu::{ExternalInterrupt, enable_global_interrupt, set_interrupt};
use xt_rv32i_hal::hb32::{EintController, Mtime, Uart};
use xt_rv32i_hal::lb::{Led, Ledsd};
use xt_rv32i_hal::{PacPeripherals, take_pac};
use xt_rv32i_pac::get_top;

static MTIMER_IRQ_FLAG: AtomicBool = AtomicBool::new(false);

#[entry]
fn main() -> ! {
    let Some(PacPeripherals {
        eintcontroller: eint,
        mtime,
        ledsd,
        led,
        ..
    }) = take_pac()
    else {
        loop {}
    };
    let mut eint = EintController::new(eint);
    let mut mtime = Mtime::new(mtime);
    unsafe {
        eint.set_enable(ExternalInterrupt::Uart.into_mask().into());
        set_interrupt::<{ (1 << MachineExternal as usize) | (1 << MachineTimer as usize) }>();
        mtime.update_mtimecmp_forward(Mtime::sec_ticks(1));
        enable_global_interrupt();
    }
    let mut ledsd = Ledsd::new(ledsd);
    let mut led = Led::new(led);
    let mut timer: u32 = 0;
    loop {
        if MTIMER_IRQ_FLAG.load(Relaxed) {
            MTIMER_IRQ_FLAG.store(false, Relaxed);
            timer += 1;
            ledsd.set_data(timer as u8);
            led.set_data(timer as u8);
            unsafe {
                mtime.update_mtimecmp_forward(Mtime::sec_ticks(1));
                set_interrupt::<{ 1 << MachineTimer as usize }>();
            }
        }
    }
}

#[unsafe(no_mangle)]
extern "riscv-interrupt-m" fn UART_RX_IRQ_Handler() {
    unsafe {
        let mut ledsd = Ledsd::new(get_top().ledsd());
        let mut uart = Uart::new(get_top().uart());
        ledsd.set_data(uart.rx());
    }
}

#[unsafe(no_mangle)]
extern "riscv-interrupt-m" fn mtimer_IRQ_Handler() {
    riscv::interrupt::disable_interrupt(MachineTimer);
    MTIMER_IRQ_FLAG.store(true, Relaxed);
}
