#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::Interrupt;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::LEDSD;
use xt_riscv_mcu::rv_core::{
    ExternalInterrupt, delay_sec, enable_global_interrupt, enable_interrupt,
};
use xt_riscv_mcu::system_peripheral::{EintController, Uart};

#[entry]
fn main() -> ! {
    let mut ledsd = LEDSD::SINGLETON;
    let mut eint = EintController::SINGLETON;
    unsafe {
        eint.set_enable(ExternalInterrupt::Uart.into_mask());
        enable_interrupt::<{ Interrupt::MachineExternal as usize }>();
        enable_global_interrupt();
    }
    loop {
        for i in 0..10 {
            ledsd.set_data(i as u8);
            delay_sec(1);
        }
        riscv::asm::wfi();
        delay_sec(1);
        unsafe { riscv::asm::ecall() }
        delay_sec(1);
    }
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn UART_RX_IRQ_Handler() {
    let mut ledsd = LEDSD::SINGLETON;
    let mut uart = Uart::SINGLETON;
    ledsd.set_data(unsafe { uart.rx_forced() });
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn Ecall_ErrorHandler() {
    let mut ledsd = LEDSD::SINGLETON;
    ledsd.set_data(0xEC);
    let mut mepc = riscv::register::mepc::read();
    mepc += 4;
    unsafe { riscv::register::mepc::write(mepc) }
}
