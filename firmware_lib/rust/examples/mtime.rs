#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::Interrupt::*;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::{LED, LEDSD};
use xt_riscv_mcu::rv_core::{ExternalInterrupt, enable_global_interrupt, set_interrupt};
use xt_riscv_mcu::system_peripheral::{EintController, Mtime, Uart};

#[entry]
fn main() -> ! {
    let mut eint = EintController::SINGLETON;
    unsafe {
        eint.set_enable(ExternalInterrupt::Uart.into_mask());
        set_interrupt::<{ (1 << MachineExternal as usize) | (1 << MachineTimer as usize) }>();
        enable_global_interrupt();
    }
    loop {}
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn UART_RX_IRQ_Handler() {
    let mut ledsd = LEDSD::SINGLETON;
    let mut uart = Uart::SINGLETON;
    ledsd.set_data(unsafe { uart.rx_forced() });
}

static mut TIMER: u32 = 0;

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn mtimer_IRQ_Handler() {
    let mut mtime = Mtime::SINGLETON;
    mtime.update_mtimecmp_forward(Mtime::sec_ticks(1));

    unsafe { TIMER += 1 }
    let mut ledsd = LEDSD::SINGLETON;
    let mut led = LED::SINGLETON;
    unsafe {
        ledsd.set_data(TIMER as u8);
        led.set_data(TIMER as u8);
    }
}
