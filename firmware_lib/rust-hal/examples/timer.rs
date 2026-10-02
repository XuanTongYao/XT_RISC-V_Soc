#![no_std]
#![no_main]
#![feature(abi_riscv_interrupt)]

use core::sync::atomic::{AtomicBool, AtomicU16, Ordering::Relaxed};
use riscv::interrupt::Interrupt;
use riscv_macros::entry;
use xt_riscv_mcu::{ExternalInterrupt, enable_global_interrupt, enable_interrupt};
use xt_rv32i_hal::hb32::{EintController, Gpio, Uart};
use xt_rv32i_hal::lb::Ledsd;
use xt_rv32i_hal::wisbone::{Timer, TimerInterrupt};
use xt_rv32i_hal::{PacPeripherals, take_pac};

const RGB_MASK: u32 = 0b111_111 << 24;

#[entry]
fn main() -> ! {
    let Some(PacPeripherals {
        eintcontroller: eint,
        uart,
        gpio,
        ledsd,
        timer,
        ..
    }) = take_pac()
    else {
        loop {}
    };
    let mut eint = EintController::new(eint);
    unsafe {
        eint.set_enable(ExternalInterrupt::Timer.into_mask().into());
        enable_interrupt::<{ Interrupt::MachineExternal as usize }>();
        enable_global_interrupt();
    }
    let mut uart = Uart::new(uart);
    let mut timer = Timer::init(timer, TimerControl0::new());
    timer.set_top_autoload(true);
    let mut gpio = Gpio::new(gpio);
    let mut ledsd = Ledsd::new(ledsd);
    ledsd.set_digit(0b11); // 关闭LED数码管
    // 控制2xRGB灯珠6个引脚 与 GPIO0
    gpio.set_direction(RGB_MASK | 0b1); // 设为输出模式
    gpio.set_data(RGB_MASK); // 熄灭(共阳极)
    for i in 24..=29 {
        gpio.set_af(i, 0); // 配置复用到定时器输出
    }
    gpio.set_af(0, 0);
    loop {
        if uart.status().rx_end() {
            let cmd = uart.rx();
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
        do_timer_irq(&mut timer);
    }
}

use xt_rv32i_hal::wisbone::TimerMode::*;
use xt_rv32i_hal::wisbone::{TimerControl0, TimerDivider, TimerDivider::*};

fn set_1hz(timer: &mut Timer) {
    let control0 = TimerControl0::new().with_prescale(Div256);
    timer.set_control0(control0);
    timer.set_mode(ToggleOnTopClearTimerOnTop);
    timer.set_top(46875);
}

fn pwm(timer: &mut Timer) {
    let control0 = TimerControl0::new().with_prescale(Div8);
    timer.set_control0(control0);
    timer.set_mode(SetClearFastPWM);
    timer.set_top(40000);
    timer.set_compare(20000);
}

fn clkdiv_up(timer: &mut Timer) {
    let div = timer.control0().prescale();
    if div != Div1024 {
        let div = (div as u8) + 1;
        timer.modify_control0(|con| con.with_prescale(TimerDivider::from_bits(div)));
    }
}

fn clkdiv_down(timer: &mut Timer) {
    let div = timer.control0().prescale();
    if div != Div1 {
        let div = (div as u8) - 1;
        timer.modify_control0(|con| con.with_prescale(TimerDivider::from_bits(div)));
    }
}

static COMPARE: AtomicU16 = AtomicU16::new(0);
static ADD: AtomicBool = AtomicBool::new(false);
static TIMER_IRQ_FLAG: AtomicBool = AtomicBool::new(false);

fn breathing_light(timer: &mut Timer, gpio: &mut Gpio) {
    gpio.set_af_enable(0b111_111 << 24);

    let control0 = TimerControl0::new().with_prescale(Div1);
    timer.set_control0(control0);
    timer.set_mode(SetClearFastPWM);
    timer.set_top(468);
    COMPARE.store(0, Relaxed);
    timer.set_compare(0);
    // 仅开启溢出中断
    timer.set_int_en(TimerInterrupt::new().with_irqovf(true));
}

fn exit_breathing_light(timer: &mut Timer) {
    // 关闭所有中断
    timer.set_int_en(TimerInterrupt::new());
}

#[unsafe(no_mangle)]
extern "riscv-interrupt-m" fn Timer_IRQ_Handler() {
    TIMER_IRQ_FLAG.store(true, Relaxed);
}

fn do_timer_irq(timer: &mut Timer) {
    if TIMER_IRQ_FLAG.load(Relaxed) {
        TIMER_IRQ_FLAG.store(false, Relaxed);
        timer.set_int_status(timer.int_status());

        let mut compare = COMPARE.load(Relaxed);
        if compare == 0 {
            ADD.store(true, Relaxed);
        } else if compare == 460 {
            ADD.store(false, Relaxed);
        }
        if ADD.load(Relaxed) {
            compare += 1;
        } else {
            compare -= 1;
        }
        COMPARE.store(compare, Relaxed);
        timer.set_compare(compare);
    }
}
