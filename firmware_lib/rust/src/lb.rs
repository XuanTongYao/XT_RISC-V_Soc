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
    use seq_macro::seq;
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
    seq!(N in 0..=7 {
        pub enum AfControlSel {
            #(
                Sel~N,
            )*
        }
    });

    seq!(N in 0..=7 {
        #[bitfield(u32)]
        pub struct FunctAfControl {
            #(
                #[bits(4)]
                pub con~N: AfControl,
            )*
        }
    });
    impl FunctAfControl {
        #[inline(always)]
        pub const fn get_control(self: Self, index: u8) -> AfControl {
            seq!(N in 0..7 {
                match index {
                    #( N => self.con~N(), )*
                    _ => self.con7(),
                }
            })
        }

        #[inline(always)]
        pub const fn modify_control(
            self: Self,
            index: u8,
            sel: Option<AfControlSel>,
            enable: Option<bool>,
        ) -> FunctAfControl {
            let mut con = self.get_control(index);
            if let Some(sel) = sel {
                con.set_sel(sel as u8);
            }
            if let Some(enable) = enable {
                con.set_enbale(enable);
            }
            seq!(N in 0..7 {
                match index {
                    #( N => self.with_con~N(con), )*
                    _ => self.with_con7(con),
                }
            })
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
pub use regs::AfControlSel;
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
        sel: Option<AfControlSel>,
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

    crate::getset_value!(data, data, u8);
    crate::getset_field!(decimal_point, control, dp, u8);
    crate::getset_field!(
        /// 低电平有效
        digit, control, dig, u8
    );
}
