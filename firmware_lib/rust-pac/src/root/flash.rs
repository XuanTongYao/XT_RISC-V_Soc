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

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        /// Reset enable
        ///
        /// Bits: `6`
        pub const fn rste(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_rste(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }

        /// WISHBONE command enable
        ///
        /// Bits: `7`
        pub const fn wbce(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_wbce(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod status {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Status(u8);
    bitfield_reg!(Status, u8, 0x00);

    impl Status {
        /// I2C激活
        ///
        /// Bits: `0`
        pub const fn i2cact(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_i2cact(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// SPI激活
        ///
        /// Bits: `1`
        pub const fn sspiact(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_sspiact(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 接收FIFO已满
        ///
        /// Bits: `2`
        pub const fn rxff(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_rxff(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 接收FIFO已空
        ///
        /// Bits: `3`
        pub const fn rxfe(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_rxfe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// 发送FIFO已满
        ///
        /// Bits: `4`
        pub const fn txff(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_txff(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// 发送FIFO已空
        ///
        /// Bits: `5`
        pub const fn txfe(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_txfe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// WB总线到配置(FPGA配置)接口激活(慎用)
        ///
        /// Bits: `7`
        pub const fn wbcact(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_wbcact(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod flash_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct FlashInterrupt(u8);
    bitfield_reg!(FlashInterrupt, u8, 0x00);

    impl FlashInterrupt {
        /// I2C激活
        ///
        /// Bits: `0`
        pub const fn i2cact(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_i2cact(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// SPI激活
        ///
        /// Bits: `1`
        pub const fn sspiact(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_sspiact(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 接收FIFO已满
        ///
        /// Bits: `2`
        pub const fn rxff(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_rxff(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 接收FIFO已空
        ///
        /// Bits: `3`
        pub const fn rxfe(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_rxfe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// 发送FIFO已满
        ///
        /// Bits: `4`
        pub const fn txff(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_txff(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// 发送FIFO已空
        ///
        /// Bits: `5`
        pub const fn txfe(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_txfe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }
    }
}
