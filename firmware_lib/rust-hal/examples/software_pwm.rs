#![no_std]
#![no_main]

use embedded_hal::digital::{OutputPin, PinState};
use panic_halt as _;
use riscv_macros::entry;
use xt_riscv_mcu::CORE_FREQ_KHZ;
use xt_rv32i_hal::hb32::{
    GpioPins, Output, into_direction_in_batches, into_dyn_pin_in_batches, set_pin_state_in_batches,
};
use xt_rv32i_hal::lb::Ledsd;
use xt_rv32i_hal::{PacPeripherals, take_pac};

#[entry]
fn main() -> ! {
    let Some(PacPeripherals { gpio, ledsd, .. }) = take_pac() else {
        loop {}
    };
    let mut ledsd = Ledsd::new(ledsd);
    ledsd.set_digit(0b11); // 关闭LED数码管

    let GpioPins {
        io29,
        io28,
        io27,
        io26,
        io25,
        io24,
        ..
    } = GpioPins::init(gpio);
    set_pin_state_in_batches(
        &mut into_direction_in_batches((io26, io25, io24)),
        PinState::High,
    ); // 关闭另一组灯

    let pins = (io29, io28, io27);
    let pins = into_direction_in_batches::<Output, _>(pins);
    let mut pins: [_; _] = into_dyn_pin_in_batches(pins).into();

    let now = riscv::register::mcycle::read();
    let mut pwm = SoftwarePwm::new(now, 0, &mut pins);
    let mut add = true;
    loop {
        let now = riscv::register::mcycle::read();
        if pwm.do_pwm(now) {
            if add {
                pwm.duty_ticks += 32;
                if pwm.duty_ticks >= PWM_CYCLE_TICKS {
                    add = false;
                    pwm.duty_ticks = PWM_CYCLE_TICKS;
                }
            } else {
                pwm.duty_ticks = pwm.duty_ticks.saturating_sub(32);
                if pwm.duty_ticks == 0 {
                    add = true;
                }
            }
        }
    }
}

const PWM_CYCLE_TICKS: usize = CORE_FREQ_KHZ as usize; // 1毫秒
struct SoftwarePwm<'a, P: OutputPin> {
    pins: &'a mut [P],
    low_level: bool,
    start_ticks: usize,
    pub duty_ticks: usize,
}

impl<'a, P: OutputPin> SoftwarePwm<'a, P> {
    fn new(start_ticks: usize, duty_ticks: usize, pins: &'a mut [P]) -> Self {
        use embedded_hal::digital::PinState::*;
        let state = if duty_ticks == 0 { Low } else { High };
        for pin in pins.iter_mut() {
            let _ = pin.set_state(state);
        }
        Self {
            pins,
            low_level: duty_ticks == 0,
            start_ticks,
            duty_ticks,
        }
    }
    /// 返回周期是否结束
    fn do_pwm(&mut self, ticks: usize) -> bool {
        if ticks.wrapping_sub(self.start_ticks) > PWM_CYCLE_TICKS {
            if self.duty_ticks != 0 && self.low_level {
                self.low_level = false;
                for pin in self.pins.iter_mut() {
                    let _ = pin.set_high();
                }
            }
            self.start_ticks = ticks;
            return true;
        } else if !self.low_level && ticks.wrapping_sub(self.start_ticks) > self.duty_ticks {
            self.low_level = true;
            for pin in self.pins.iter_mut() {
                let _ = pin.set_low();
            }
        }
        return false;
    }
}
