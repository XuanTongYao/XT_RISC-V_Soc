use crate::common::register::*;

#[repr(C)]
pub struct Spi {
    /// 所有延迟周期的精度为0.5个SCK周期，最短0.5.
    pub control0: RW<control0::Control0>,
    pub control1: RW<control1::Control1>,
    pub control2: RW<control2::Control2>,
    /// 时钟预分频 [1,63]. 实际时钟频率为 `WISHBONE/(div+1)`. 写入会使SPI复位。
    pub clock_prescale: RW<u8>,
    /// 主机模式片选. 写入会使SPI复位.
    pub cs: RW<u8>,
    /// Transmit data
    pub tx_data: WO<u8>,
    pub status: RO<status::Status>,
    /// Receive data
    pub rx_data: RO<u8>,
    /// 中断状态
    ///
    /// # Note
    /// - Bitwise write one to clear
    pub int_status: RW<spi_interrupt::SpiInterrupt>,
    /// 中断启用
    pub int_en: RW<spi_interrupt::SpiInterrupt>,
}

pub mod control0 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control0(u8);
    bitfield_reg!(Control0, u8, 0x00);

    impl Control0 {
        /// 前导延迟周期
        ///
        /// Bits: `2..0`
        pub const fn tlead_xcnt(&self) -> u8 {
            (self.0 & 0x07) >> 0
        }
        pub const fn with_tlead_xcnt(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x07) | ((value as u8) << 0);
            self
        }

        /// 尾随延迟周期
        ///
        /// Bits: `5..3`
        pub const fn ttrail_xcnt(&self) -> u8 {
            (self.0 & 0x38) >> 3
        }
        pub const fn with_ttrail_xcnt(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x38) | ((value as u8) << 3);
            self
        }

        /// 空闲延迟周期
        ///
        /// Bits: `7..6`
        pub const fn tidle_xcnt(&self) -> u8 {
            (self.0 & 0xC0) >> 6
        }
        pub const fn with_tidle_xcnt(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0xC0) | ((value as u8) << 6);
            self
        }
    }
}

pub mod control1 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control1(u8);
    bitfield_reg!(Control1, u8, 0x00);

    impl Control1 {
        /// Transmit edge
        ///
        /// Bits: `4`
        pub const fn txedge(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_txedge(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// Wakeup enable (config)
        ///
        /// Bits: `5`
        pub const fn wkupen_cfg(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_wkupen_cfg(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// Wakeup enable (user)
        ///
        /// Bits: `6`
        pub const fn wkupen_user(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_wkupen_user(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }

        /// SPI enable
        ///
        /// Bits: `7`
        pub const fn spe(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_spe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod control2 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control2(u8);
    bitfield_reg!(Control2, u8, 0x00);

    impl Control2 {
        /// LSB first
        ///
        /// Bits: `0`
        pub const fn lsbf(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_lsbf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// Clock phase (second edge)
        ///
        /// Bits: `1`
        pub const fn cpha(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_cpha(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// Clock polarity (active low)
        ///
        /// Bits: `2`
        pub const fn cpol(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_cpol(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// Master holds chip select low even if there is no data to be transmitted
        ///
        /// Bits: `6`
        pub const fn mcsh(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_mcsh(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }

        /// Master mode
        ///
        /// Bits: `7`
        pub const fn mstr(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_mstr(mut self, value: bool) -> Self {
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
        /// Mode fault
        ///
        /// Bits: `0`
        pub const fn mdf(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_mdf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// Receive overflow
        ///
        /// Bits: `1`
        pub const fn roe(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_roe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// Receive ready
        ///
        /// Bits: `3`
        pub const fn rrdy(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_rrdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// Transmit ready
        ///
        /// Bits: `4`
        pub const fn trdy(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_trdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// Transfer in progress
        ///
        /// Bits: `7`
        pub const fn tip(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_tip(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod spi_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct SpiInterrupt(u8);
    bitfield_reg!(SpiInterrupt, u8, 0x00);

    impl SpiInterrupt {
        /// 模式错误，在主机模式时自身片选被拉低
        ///
        /// Bits: `0`
        pub const fn irqmdf(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_irqmdf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 接收溢出
        ///
        /// Bits: `1`
        pub const fn irqroe(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_irqroe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 接收就绪
        ///
        /// Bits: `3`
        pub const fn irqrrdy(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_irqrrdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// 发送就绪
        ///
        /// Bits: `4`
        pub const fn irqtrdy(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_irqtrdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }
    }
}
