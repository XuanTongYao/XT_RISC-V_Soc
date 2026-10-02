use crate::common::register::*;

#[repr(C)]
pub struct KeySwitch {
    pub key: RO<u8>,
    pub switch: RO<u8>,
}

pub type InstanceKeySwitch = RegisterBlock<KeySwitch>;
