#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use core::sync::atomic::{AtomicU16, Ordering};
use riscv::interrupt::Interrupt;
use xt_riscv_mcu::entry;
use xt_riscv_mcu::hb32::{EintController, Gpio, Uart};
use xt_riscv_mcu::lb::LEDSD;
use xt_riscv_mcu::wisbone::Timer;
use xt_riscv_mcu::{ExternalInterrupt, enable_global_interrupt, enable_interrupt};

const RGB_MASK: u32 = 0b111_111 << 24;

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
    let mut gpio = Gpio::SINGLETON;
    let mut ledsd = LEDSD::SINGLETON;
    ledsd.set_digit(0b11); // 关闭LED数码管
    // 控制2xRGB灯珠6个引脚 与 GPIO0
    gpio.set_direction(RGB_MASK | 0b1); // 设为输出模式
    gpio.set_data(RGB_MASK); // 熄灭(共阳极)
    for i in 24..=29 {
        gpio.set_af(i, 0); // 配置复用到定时器输出
    }
    gpio.set_af(0, 0);
    loop {
        let cmd = uart.rx_block();
        match cmd {
            0x00 => set_1hz(&mut timer),
            0x01 => pwm(&mut timer),
            0x02 => clkdiv_up(&mut timer),
            0x03 => clkdiv_down(&mut timer),
            0x04 => breathing_light(&mut timer, &mut gpio),
            0x05 => exit_breathing_light(&mut timer),
            0x06 => gpio.modify_af_enable(|val| val | (RGB_MASK)), // RGB引脚开启功能复用
            0x07 => gpio.modify_af_enable(|val| val & !(RGB_MASK)), // RGB引脚关闭功能复用
            0x08 => gpio.modify_af_enable(|val| val | (0b100_100 << 24)), // 红色LED引脚开启功能复用
            0x09 => gpio.modify_af_enable(|val| val | (0b100_100 << 23)), // 绿色LED引脚开启功能复用
            0x0a => gpio.modify_af_enable(|val| val | (0b100_100 << 22)), // 蓝色LED引脚开启功能复用
            0x0b => gpio.modify_af_enable(|val| val | (uart.rx_block() as u32) << 24), // 设置RGB引脚复用
            0x0c => gpio.modify_af_enable(|val| val | 0b1), // GPIO0开启功能复用
            0x0d => gpio.modify_af_enable(|val| val & !0b1), // GPIO0关闭功能复用
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

static COMPARE: AtomicU16 = AtomicU16::new(0);

fn breathing_light(timer: &mut Timer, gpio: &mut Gpio) {
    gpio.set_af_enable(0b111_111 << 24);

    let control0 = TimerControl0::new().with_prescale(Div1).with_clkedge(false);
    let control1 = TimerControl1::new().with_tcm(FastPWM).with_ocm(SetClear);
    timer.set_control0(control0);
    timer.set_control1(control1);
    timer.set_top(468);
    unsafe {
        COMPARE.store(0, Ordering::Relaxed);
        timer.set_compare(0);
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
    static mut ADD: bool = false;
    let mut timer = Timer::SINGLETON;
    let int_status = timer.reg().int_status.read();
    if !int_status.irqovf() {
        return;
    }
    unsafe { timer.reg().int_status.write(int_status) }

    let mut compare = COMPARE.load(Ordering::Relaxed);
    unsafe {
        if compare == 0 {
            ADD = true;
        } else if compare == 460 {
            ADD = false;
        }
        if ADD {
            compare += 1;
        } else {
            compare -= 1;
        }
    }
    COMPARE.store(compare, Ordering::Relaxed);
    timer.set_compare(compare);
}
