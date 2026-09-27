//! 低速总线外设，包含按钮、LED、数码管等

use crate::pac::key_switch::InstanceKeySwitch;
use crate::pac::led::InstanceLed;
use crate::pac::ledsd::InstanceLedsd;

pub struct KeySwitch {
    inst: InstanceKeySwitch,
}
impl KeySwitch {
    pub fn new(inst: InstanceKeySwitch) -> Self {
        Self { inst }
    }
    crate::prop_value!(key, key, u8, get);
    crate::prop_value!(switch, switch, u8, get);
}

pub struct Led {
    inst: InstanceLed,
}
impl Led {
    pub fn new(inst: InstanceLed) -> Self {
        Self { inst }
    }
    crate::prop_value!(data, data, u8, get, set);
}

pub struct Ledsd {
    inst: InstanceLedsd,
}
impl Ledsd {
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
