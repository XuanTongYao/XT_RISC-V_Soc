use crate::common::register::*;

#[repr(C)]
pub struct Msip {
    pub msip: RW<msip::Msip>,
}

pub type InstanceMsip = RegisterBlock<Msip>;

pub mod msip {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Msip(u32);
    bitfield_reg!(Msip, u32, 0x00000000);

    impl Msip {
        bitfield_accessor!(
            u32, bool, pending, with_pending, 0x00000001, 0
            /// Bits: `0`
        );
    }
}
