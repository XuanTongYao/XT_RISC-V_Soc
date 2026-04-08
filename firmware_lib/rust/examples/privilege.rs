#![no_std]
#![no_main]

use riscv::interrupt::Interrupt;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::LEDSD;
use xt_riscv_mcu::rv_core::{delay_sec, enable_global_interrupt, enable_interrupt};
use xt_riscv_mcu::system_peripheral::{EintController, EintMask, Uart};

#[entry]
fn main() -> ! {
    let mut ledsd = LEDSD::SINGLETON;
    let mut eint = EintController::SINGLETON;
    unsafe {
        eint.set_enable(EintMask::UART.bits());
        enable_interrupt::<{ Interrupt::MachineExternal as usize }>();
        enable_global_interrupt();
    }
    loop {
        for i in 0..10 {
            ledsd.display(i as u8);
            delay_sec(1);
        }
        riscv::asm::wfi();
        delay_sec(1);
        unsafe { riscv::asm::ecall() }
        delay_sec(1);
    }
}

#[unsafe(no_mangle)]
#[unsafe(naked)]
unsafe extern "C" fn UART_RX_IRQ_Handler() {
    core::arch::naked_asm!(
        "addi sp, sp, -16",
        "sw ra, 12(sp)",
        "sw a0, 8(sp)",
        "sw a1, 4(sp)",

        "call {}",

        "lw a1, 4(sp)",
        "lw a0, 8(sp)",
        "lw ra, 12(sp)",
        "addi sp, sp, 16",
        "mret",
        sym uart_rx_irq_handler,
    );
}

/// # FIXME
/// 中断不能正常工作，能工作就是巧合
unsafe extern "C" fn uart_rx_irq_handler() {
    let mut ledsd = LEDSD::SINGLETON;
    let mut uart = Uart::SINGLETON;
    ledsd.display(unsafe { uart.rx_forced() });
}

#[unsafe(no_mangle)]
unsafe extern "C" fn Ecall_ErrorHandler() {
    let mut ledsd = LEDSD::SINGLETON;
    ledsd.display(0xEC);
    let mut mepc = riscv::register::mepc::read();
    mepc += 4;
    unsafe { riscv::register::mepc::write(mepc) }
}
