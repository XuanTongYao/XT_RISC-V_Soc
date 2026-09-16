use crate::common::register::*;

#[repr(C)]
pub struct EintController {
    pub enable: RW<interrupt::Interrupt>,
    pub pending: RO<interrupt::Interrupt>,
}

pub mod interrupt {
    use crate::common::register::*;

    #[derive(Clone, Copy)]
    pub struct Interrupt(u32);
    bitfield_reg!(Interrupt, u32, 0);

    impl Interrupt {
        /// Bits: `0`
        pub const fn uart(&self) -> bool {
            ((self.0 & 0x00000001) >> 0) != 0
        }
        pub const fn with_uart(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000001) | ((value as u32) << 0);
            self
        }

        /// Bits: `8`
        pub const fn i2c1(&self) -> bool {
            ((self.0 & 0x00000100) >> 8) != 0
        }
        pub const fn with_i2c1(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000100) | ((value as u32) << 8);
            self
        }

        /// Bits: `9`
        pub const fn i2c2(&self) -> bool {
            ((self.0 & 0x00000200) >> 9) != 0
        }
        pub const fn with_i2c2(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000200) | ((value as u32) << 9);
            self
        }

        /// Bits: `10`
        pub const fn spi(&self) -> bool {
            ((self.0 & 0x00000400) >> 10) != 0
        }
        pub const fn with_spi(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000400) | ((value as u32) << 10);
            self
        }

        /// Bits: `11`
        pub const fn timer(&self) -> bool {
            ((self.0 & 0x00000800) >> 11) != 0
        }
        pub const fn with_timer(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000800) | ((value as u32) << 11);
            self
        }

        /// Bits: `12`
        pub const fn wbcufm(&self) -> bool {
            ((self.0 & 0x00001000) >> 12) != 0
        }
        pub const fn with_wbcufm(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00001000) | ((value as u32) << 12);
            self
        }
    }
}
