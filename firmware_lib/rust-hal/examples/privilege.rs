#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use riscv::interrupt::{Exception, Interrupt, Trap};
use riscv_macros::entry;
use xt_riscv_mcu::{ExternalInterrupt, delay_sec, enable_global_interrupt, enable_interrupt};
use xt_rv32i_hal::hb32::{EintController, Uart};
use xt_rv32i_hal::lb::Ledsd;
use xt_rv32i_hal::{PacPeripherals, take_pac};
use xt_rv32i_pac::get_top;

#[entry]
fn main() -> ! {
    let Some(PacPeripherals {
        eintcontroller: eint,
        ledsd,
        ..
    }) = take_pac()
    else {
        loop {}
    };
    let mut ledsd = Ledsd::new(ledsd);
    let mut eint = EintController::new(eint);
    unsafe {
        eint.set_enable(ExternalInterrupt::Uart.into_mask().into());
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
extern "riscv-interrupt-m" fn UART_RX_IRQ_Handler() {
    unsafe {
        let mut ledsd = Ledsd::new(get_top().ledsd());
        let mut uart = Uart::new(get_top().uart());
        ledsd.set_data(uart.rx());
    }
}

#[inline(always)]
unsafe fn ecall_error_handler() {
    let mut ledsd = unsafe { Ledsd::new(get_top().ledsd()) };
    ledsd.set_data(0xEC);
    let mut mepc = riscv::register::mepc::read();
    mepc += 4;
    unsafe { riscv::register::mepc::write(mepc) }
}

#[unsafe(no_mangle)]
extern "riscv-interrupt-m" fn Exception_Handler() {
    let Ok(code) = riscv::interrupt::machine::try_cause::<Interrupt, Exception>() else {
        unsafe { xt_riscv_mcu::goto_unhandled_fault() }
    };

    unsafe {
        match code {
            Trap::Exception(Exception::MachineEnvCall) => ecall_error_handler(),
            _ => xt_riscv_mcu::goto_unhandled_fault(),
        }
    }
}
