use crate::common::register::*;

#[repr(C)]
pub struct Flash {
    /// Flash control. Reset writes RSTE=1 (0x40). Command frame asserts WBCE then deasserts it.
    pub control: RW<control::Control>,
    pub write_data: WO<u8>,
    pub status: RO<status::Status>,
    pub read_data: RO<u8>,
    /// 中断状态
    ///
    /// # Note
    /// - Bitwise write one to clear
    pub int_status: RW<flash_interrupt::FlashInterrupt>,
    /// 中断启用
    pub int_en: RW<flash_interrupt::FlashInterrupt>,
}

pub type InstanceFlash = RegisterBlock<Flash>;

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        bitfield_accessor!(
            u8, bool, rste, with_rste, 0x40, 6
            /// Reset enable
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, wbce, with_wbce, 0x80, 7
            /// WISHBONE command enable
            ///
            /// Bits: `7`
        );
    }
}

pub mod status {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Status(u8);
    bitfield_reg!(Status, u8, 0x00);

    impl Status {
        bitfield_accessor!(
            u8, bool, i2cact, with_i2cact, 0x01, 0
            /// I2C激活
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, sspiact, with_sspiact, 0x02, 1
            /// SPI激活
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, rxff, with_rxff, 0x04, 2
            /// 接收FIFO已满
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, rxfe, with_rxfe, 0x08, 3
            /// 接收FIFO已空
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, txff, with_txff, 0x10, 4
            /// 发送FIFO已满
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, txfe, with_txfe, 0x20, 5
            /// 发送FIFO已空
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, wbcact, with_wbcact, 0x80, 7
            /// WB总线到配置(FPGA配置)接口激活(慎用)
            ///
            /// Bits: `7`
        );
    }
}

pub mod flash_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct FlashInterrupt(u8);
    bitfield_reg!(FlashInterrupt, u8, 0x00);

    impl FlashInterrupt {
        bitfield_accessor!(
            u8, bool, i2cact, with_i2cact, 0x01, 0
            /// I2C激活
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, sspiact, with_sspiact, 0x02, 1
            /// SPI激活
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, rxff, with_rxff, 0x04, 2
            /// 接收FIFO已满
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, rxfe, with_rxfe, 0x08, 3
            /// 接收FIFO已空
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, txff, with_txff, 0x10, 4
            /// 发送FIFO已满
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, txfe, with_txfe, 0x20, 5
            /// 发送FIFO已空
            ///
            /// Bits: `5`
        );
    }
}
