use crate::common::register::*;

#[repr(C)]
pub struct Gpio {
    /// GPIO 方向。 1 = 输出，0 = 输入
    pub direction: RW<u32>,
    pub data: RW<u32>,
    /// 复用功能启用
    pub af_enable: RW<u32>,
    /// GPIO 0-15 的复用选择，每个引脚2 bits
    pub afl: RW<u32>,
    /// GPIO 16-27 的复用选择，每个引脚2 bits
    pub afh: RW<u32>,
}
