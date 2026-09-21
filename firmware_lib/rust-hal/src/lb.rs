//! 低速总线外设，包含按钮、LED、数码管等

use crate::pac::common::register::RegisterBlock;
use xt_rv32i_pac::get_top;
use xt_rv32i_pac::root::key_switch;
use xt_rv32i_pac::root::led;
use xt_rv32i_pac::root::ledsd;

type InstanceKeySwitch = RegisterBlock<key_switch::KeySwitch>;
pub struct KeySwitch {
    inst: InstanceKeySwitch,
}
impl KeySwitch {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().keyswitch() })
    }
    pub fn new(inst: InstanceKeySwitch) -> Self {
        Self { inst }
    }
    crate::prop_value!(key, key, u8, get);
    crate::prop_value!(switch, switch, u8, get);
}

type InstanceLed = RegisterBlock<led::Led>;
pub struct Led {
    inst: InstanceLed,
}
impl Led {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().led() })
    }
    pub fn new(inst: InstanceLed) -> Self {
        Self { inst }
    }
    crate::prop_value!(data, data, u8, get, set);
}

type InstanceLedsd = RegisterBlock<ledsd::Ledsd>;
pub struct Ledsd {
    inst: InstanceLedsd,
}
impl Ledsd {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().ledsd() })
    }
    pub fn new(inst: InstanceLedsd) -> Self {
        Self { inst }
    }
    crate::prop_value!(data, data, u8, get, set);
    crate::getset_field!(decimal_point, control, dp, u8);
    crate::getset_field!(
        /// 低电平有效
        digit,
        control,
        dig,
        u8
    );
}
