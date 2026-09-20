use crate::common::register::*;

#[repr(C)]
pub struct Msip {
    pub msip: RW<msip::Msip>,
}

pub mod msip {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Msip(u32);
    bitfield_reg!(Msip, u32, 0x00000000);

    impl Msip {
        /// Bits: `0`
        pub const fn pending(&self) -> bool {
            ((self.0 & 0x00000001) >> 0) != 0
        }
        pub const fn with_pending(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x00000001) | ((value as u32) << 0);
            self
        }
    }
}
