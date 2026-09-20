//! 低速总线外设，包含按钮、LED、数码管等

use xt_rv32i_pac::get_top;
use xt_rv32i_pac::root::key_switch;
use xt_rv32i_pac::root::led;
use xt_rv32i_pac::root::ledsd;

use crate::common::Peripheral;

pub type KeySwitch = Peripheral<key_switch::KeySwitch>;
impl KeySwitch {
    pub const SINGLETON: Self = unsafe { Self::from_rb(get_top().keyswitch()) };
    crate::get_value!(key, key, u8);
    crate::get_value!(switch, switch, u8);
}

pub type LED = Peripheral<led::Led>;
impl LED {
    pub const SINGLETON: Self = unsafe { Self::from_rb(get_top().led()) };
    crate::getset_value!(data, data, u8);
}

pub type LEDSD = Peripheral<ledsd::Ledsd>;
impl LEDSD {
    pub const SINGLETON: Self = unsafe { Self::from_rb(get_top().ledsd()) };

    crate::getset_value!(data, data, u8);
    crate::getset_field!(decimal_point, control, dp, u8);
    crate::getset_field!(
        /// 低电平有效
        digit,
        control,
        dig,
        u8
    );
}
