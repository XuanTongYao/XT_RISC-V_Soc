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
    AfGpio, // 暂时占用，避免改变原地址
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
        pub key: RO<u8>, // 按下时为高电平(已经在硬件做了翻转)
        pub switch: RO<u8>,
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
    crate::get_value!(key, key, u8);
    crate::get_value!(switch, switch, u8);
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
