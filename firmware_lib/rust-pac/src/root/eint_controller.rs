use crate::common::register::*;

#[repr(C)]
pub struct EintController {
    pub enable: RW<interrupt::Interrupt>,
    pub pending: RO<interrupt::Interrupt>,
}

pub type InstanceEintController = RegisterBlock<EintController>;

pub mod interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Interrupt(u32);
    bitfield_reg!(Interrupt, u32, 0x00000000);

    impl Interrupt {
        bitfield_accessor!(
            u32, bool, uart, with_uart, 0x00000001, 0
            /// Bits: `0`
        );

        bitfield_accessor!(
            u32, bool, i2c1, with_i2c1, 0x00000100, 8
            /// Bits: `8`
        );

        bitfield_accessor!(
            u32, bool, i2c2, with_i2c2, 0x00000200, 9
            /// Bits: `9`
        );

        bitfield_accessor!(
            u32, bool, spi, with_spi, 0x00000400, 10
            /// Bits: `10`
        );

        bitfield_accessor!(
            u32, bool, timer, with_timer, 0x00000800, 11
            /// Bits: `11`
        );

        bitfield_accessor!(
            u32, bool, wbcufm, with_wbcufm, 0x00001000, 12
            /// Bits: `12`
        );
    }
}
