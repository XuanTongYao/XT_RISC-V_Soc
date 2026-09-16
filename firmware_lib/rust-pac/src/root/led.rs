use crate::common::register::*;

#[repr(C)]
pub struct Led {
    pub data: RW<u8>,
}
