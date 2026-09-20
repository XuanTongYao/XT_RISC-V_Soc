use crate::common::register::*;

#[repr(C)]
pub struct EfbIntSource {
    /// EFB 中断源标志
    pub source: RW<source::Source>,
}

pub mod source {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Source(u8);
    bitfield_reg!(Source, u8, 0x00);

    impl Source {
        /// Bits: `0`
        pub const fn i2c1(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_i2c1(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// Bits: `1`
        pub const fn i2c2(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_i2c2(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// Bits: `2`
        pub const fn spi(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_spi(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// Bits: `3`
        pub const fn tc(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_tc(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// Bits: `4`
        pub const fn ufmcfg(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_ufmcfg(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }
    }
}
