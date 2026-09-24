use crate::common::register::*;

#[repr(C)]
pub struct Ledsd {
    pub data: RW<u8>,
    /// 显示控制
    pub control: RW<control::Control>,
}

pub type InstanceLedsd = RegisterBlock<Ledsd>;

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        bitfield_accessor!(
            u8, u8, dp, with_dp, 0x03, 0
            /// 小数点
            ///
            /// Bits: `1..0`
        );

        bitfield_accessor!(
            u8, u8, dig, with_dig, 0x0C, 2
            /// 位选择，低电平有效
            ///
            /// Bits: `3..2`
        );
    }
}
