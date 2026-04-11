#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use AfControlSel::{Sel6, Sel7};
use riscv::interrupt::Interrupt;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::lb::{AfControlSel, AfGpio, GpioAlternateFunction, OutAF};
use xt_riscv_mcu::rv_core::{ExternalInterrupt, enable_global_interrupt, enable_interrupt};
use xt_riscv_mcu::system_peripheral::{EintController, Uart};
use xt_riscv_mcu::wisbone::Timer;

const TIMER_AF: GpioAlternateFunction = GpioAlternateFunction::Output(OutAF::TimerOutput);
const SPI_AF: GpioAlternateFunction = GpioAlternateFunction::Output(OutAF::SpiCs2);

#[entry]
fn main() -> ! {
    let mut eint = EintController::SINGLETON;
    unsafe {
        eint.set_enable(ExternalInterrupt::Timer.into_mask());
        enable_interrupt::<{ Interrupt::MachineExternal as usize }>();
        enable_global_interrupt();
    }
    let mut uart = Uart::SINGLETON;
    let mut timer = Timer::SINGLETON;
    let mut gpio = AfGpio::SINGLETON;
    gpio.set_direction(0xFC000000);
    gpio.set_data(0xFC000000);
    loop {
        let cmd = uart.rx_block();
        match cmd {
            0x00 => set_1hz(&mut timer),
            0x01 => pwm(&mut timer),
            0x02 => clkdiv_up(&mut timer),
            0x03 => clkdiv_down(&mut timer),
            0x04 => breathing_light(&mut timer, &mut gpio),
            0x05 => exit_breathing_light(&mut timer),
            0x06 => gpio.set_af_control(TIMER_AF, None, Some(false)), // 关闭定时器复用
            0x07 => gpio.set_af_control(TIMER_AF, None, Some(true)),  // 开启定时器复用
            0x08 => gpio.set_af_control(TIMER_AF, Some(Sel7), None),  // 红色LED
            0x09 => gpio.set_af_control(TIMER_AF, Some(Sel6), None),  // 绿色LED
            0x0a => gpio.set_af_control(SPI_AF, Some(Sel6), Some(true)), // 开启SPI复用
            0x0b => gpio.set_af_control(SPI_AF, None, Some(false)),   // 关闭SPI复用
            _ => (),
        }
    }
}

use xt_riscv_mcu::wisbone::regs::{
    TimerControl0, TimerControl1, TimerCounterMode::*, TimerDivider, TimerDivider::*,
    TimerOutputMode::*,
};

fn set_1hz(timer: &mut Timer) {
    let control0 = TimerControl0::new()
        .with_prescale(Div256)
        .with_clkedge(false);
    let control1 = TimerControl1::new().with_tcm(FastPWM).with_ocm(Toggle);
    timer.set_control0(control0);
    timer.set_control1(control1);
    timer.set_top(46875);
}

fn pwm(timer: &mut Timer) {
    let control0 = TimerControl0::new().with_prescale(Div8).with_clkedge(true);
    let control1 = TimerControl1::new().with_tcm(FastPWM).with_ocm(SetClear);
    timer.set_control0(control0);
    timer.set_control1(control1);
    timer.set_top(40000);
    timer.set_compare(20000);
}

fn clkdiv_up(timer: &mut Timer) {
    let div = timer.prescale();
    if div != Div1024 {
        let div = (div as u8) + 1;
        timer.set_prescale(TimerDivider::from_bits(div));
    }
}

fn clkdiv_down(timer: &mut Timer) {
    let div = timer.prescale();
    if div != Div1 {
        let div = (div as u8) - 1;
        timer.set_prescale(TimerDivider::from_bits(div));
    }
}

static mut COMPARE: u16 = 0;
static mut ADD: bool = false;

fn breathing_light(timer: &mut Timer, gpio: &mut AfGpio) {
    gpio.set_af_control(TIMER_AF, Some(Sel7), Some(true));

    let control0 = TimerControl0::new()
        .with_prescale(Div256)
        .with_clkedge(false);
    let control1 = TimerControl1::new().with_tcm(FastPWM).with_ocm(SetClear);
    timer.set_control0(control0);
    timer.set_control1(control1);
    timer.set_top(468);
    unsafe {
        COMPARE = 0;
        timer.set_compare(COMPARE);
        // 开启溢出中断
        timer.reg().int_en.modify(|reg| reg.with_irqovf(true));
    }
}

fn exit_breathing_light(timer: &mut Timer) {
    unsafe {
        // 关闭溢出中断
        timer.reg().int_en.modify(|reg| reg.with_irqovf(false));
    }
}

#[unsafe(no_mangle)]
unsafe extern "riscv-interrupt-m" fn Timer_IRQ_Handler() {
    let mut timer = Timer::SINGLETON;
    let int_status = timer.reg().int_status.read();
    if !int_status.irqovf() {
        return;
    }
    unsafe { timer.reg().int_status.write(int_status) }

    unsafe {
        if COMPARE == 460 || COMPARE == 0 {
            ADD = !ADD
        }
        if ADD {
            COMPARE += 1
        } else {
            COMPARE -= 1
        }
        timer.set_compare(COMPARE);
    }
}
