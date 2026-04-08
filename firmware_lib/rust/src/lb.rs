//! 低速总线外设，包含按钮、gpio等

use volatile_register::RW;

use crate::common::Peripheral;
const DOMAIN_XT_LB_BASE: usize = crate::common::domain_base(4);
const LB_ADDR_LEN: usize = 8;
const LB_ID_LEN: usize = 2;
const LB_OFFSET_LEN: usize = LB_ADDR_LEN - LB_ID_LEN;
const LB_ID_START_BIT: usize = LB_OFFSET_LEN;
enum PeripheralId {
    KeySwitch,
    AfGpio,
    LED,
    LEDSD,
}

const fn lb_base(statr_id: PeripheralId) -> usize {
    DOMAIN_XT_LB_BASE + ((statr_id as usize) << LB_ID_START_BIT)
}

pub mod regs {
    use bitfield_struct::bitfield;
    use volatile_register::{RO, RW};

    #[repr(C)]
    pub struct KeySwitch {
        pub key: RO<u16>, // 按下时为高电平(已经在硬件做了翻转)
        pub switch: RO<u16>,
    }

    #[repr(C)]
    pub struct AfGpio {
        pub direction: RW<u32>,
        pub data: RW<u32>,
        pub in_af_control: RW<FunctAfControl>,
        pub out_af_control: RW<FunctAfControl>,
    }

    #[bitfield(u8)]
    pub struct AfControl {
        #[bits(3)]
        pub sel: u8,
        #[bits(1)]
        pub enbale: bool,
        #[bits(4)]
        __: u8,
    }

    #[bitfield(u32)]
    pub struct FunctAfControl {
        #[bits(4)]
        pub con0: AfControl,
        #[bits(4)]
        pub con1: AfControl,
        #[bits(4)]
        pub con2: AfControl,
        #[bits(4)]
        pub con3: AfControl,
        #[bits(4)]
        pub con4: AfControl,
        #[bits(4)]
        pub con5: AfControl,
        #[bits(4)]
        pub con6: AfControl,
        #[bits(4)]
        pub con7: AfControl,
    }
    impl FunctAfControl {
        #[inline(always)]
        pub const fn get_control(self: Self, index: u8) -> AfControl {
            match index {
                0 => self.con0(),
                1 => self.con1(),
                2 => self.con2(),
                3 => self.con3(),
                4 => self.con4(),
                5 => self.con5(),
                6 => self.con6(),
                _ => self.con7(),
            }
        }

        #[inline(always)]
        pub const fn modify_control(
            self: Self,
            index: u8,
            sel: Option<u8>,
            enable: Option<bool>,
        ) -> FunctAfControl {
            let mut con = self.get_control(index);
            if let Some(sel) = sel {
                con.set_sel(sel);
            }
            if let Some(enable) = enable {
                con.set_enbale(enable);
            }
            match index {
                0 => self.with_con0(con),
                1 => self.with_con1(con),
                2 => self.with_con2(con),
                3 => self.with_con3(con),
                4 => self.with_con4(con),
                5 => self.with_con5(con),
                6 => self.with_con6(con),
                _ => self.with_con7(con),
            }
        }
    }

    #[repr(C)]
    pub struct Ledsd {
        pub data: RW<u8>,
        pub control: RW<LedsdControl>,
    }

    #[bitfield(u8)]
    pub struct LedsdControl {
        #[bits(2)]
        pub dp: u8,
        #[bits(2)]
        pub dig: u8,
        #[bits(4)]
        __: u8,
    }
}

pub type KeySwitch = Peripheral<regs::KeySwitch, { lb_base(PeripheralId::KeySwitch) }>;
impl KeySwitch {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };
    crate::get_value!(key, key, u16);
    crate::get_value!(switch, switch, u16);
}

pub type AfGpio = Peripheral<regs::AfGpio, { lb_base(PeripheralId::AfGpio) }>;
use regs::AfControl;
#[derive(Clone, Copy)]
pub enum InAF {
    TimerRst,
    TimerInput,
}
#[derive(Clone, Copy)]
pub enum OutAF {
    TimerOutput,
    SpiCs2,
}
pub enum GpioAlternateFunction {
    Input(InAF),
    Output(OutAF),
}
impl AfGpio {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    crate::getset_value!(direction, direction, u32);
    crate::getset_value!(data, data, u32);

    #[inline(always)]
    pub fn af_control(&self, gpio_af: GpioAlternateFunction) -> AfControl {
        use GpioAlternateFunction::{Input, Output};
        match gpio_af {
            Input(af) => self.reg().in_af_control.read().get_control(af as u8),
            Output(af) => self.reg().out_af_control.read().get_control(af as u8),
        }
    }

    #[inline(always)]
    pub fn set_af_control(
        &mut self,
        gpio_af: GpioAlternateFunction,
        sel: Option<u8>,
        enable: Option<bool>,
    ) {
        use GpioAlternateFunction::{Input, Output};
        unsafe {
            match gpio_af {
                Input(af) => self
                    .reg()
                    .in_af_control
                    .modify(|fac| fac.modify_control(af as u8, sel, enable)),
                Output(af) => self
                    .reg()
                    .out_af_control
                    .modify(|fac| fac.modify_control(af as u8, sel, enable)),
            };
        }
    }
}

pub type LED = Peripheral<RW<u8>, { lb_base(PeripheralId::LED) }>;
impl LED {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };
    crate::getset_value!(data,,u8);
}

pub type LEDSD = Peripheral<regs::Ledsd, { lb_base(PeripheralId::LEDSD) }>;
impl LEDSD {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    #[inline(always)]
    pub fn get_data(&self) -> u8 {
        self.reg().data.read()
    }

    #[inline(always)]
    pub fn display(&mut self, data: u8) {
        unsafe { self.reg().data.write(data) }
    }

    crate::getset_field!(decimal_point, control, dp, u8);

    crate::getset_field!(
        /// 低电平有效
        digit, control, dig, u8
    );
}
