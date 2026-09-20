use crate::common::register::*;

#[repr(C)]
pub struct Ledsd {
    pub data: RW<u8>,
    /// 显示控制
    pub control: RW<control::Control>,
}

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        /// 小数点
        ///
        /// Bits: `1..0`
        pub const fn dp(&self) -> u8 {
            (self.0 & 0x03) >> 0
        }
        pub const fn with_dp(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x03) | ((value as u8) << 0);
            self
        }

        /// 位选择，低电平有效
        ///
        /// Bits: `3..2`
        pub const fn dig(&self) -> u8 {
            (self.0 & 0x0C) >> 2
        }
        pub const fn with_dig(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x0C) | ((value as u8) << 2);
            self
        }
    }
}
