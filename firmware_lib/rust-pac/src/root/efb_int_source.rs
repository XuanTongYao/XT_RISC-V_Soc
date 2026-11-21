use crate::common::register::*;

#[repr(C)]
pub struct EfbIntSource {
    /// EFB 中断源标志
    pub source: RO<source::Source>,
}

pub type InstanceEfbIntSource = RegisterBlock<EfbIntSource>;

pub mod source {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Source(u8);
    bitfield_reg!(Source, u8, 0x00);

    impl Source {
        bitfield_accessor!(
            u8, bool, i2c1, 0x01, 0
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, i2c2, 0x02, 1
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, spi, 0x04, 2
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, tc, 0x08, 3
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, ufmcfg, 0x10, 4
            /// Bits: `4`
        );
    }
}
