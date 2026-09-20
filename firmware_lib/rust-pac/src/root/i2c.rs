use crate::common::register::*;

#[repr(C)]
pub struct I2c {
    /// 写入会导致I2C复位.
    pub control: RW<control::Control>,
    pub command: RW<command::Command>,
    /// 时钟预分频低8位。 预分频值共有10位 (PRESCALE_MASK = 0x3FF)。
    pub br0: RW<u8>,
    /// 时钟预分频高2位。 写入会导致I2C复位。
    pub br1: RW<br1::Br1>,
    /// Transmit data
    pub tx_data: WO<u8>,
    pub status: RO<status::Status>,
    pub general_call_data: RO<u8>,
    /// Receive data
    pub rx_data: RO<u8>,
    /// 中断状态
    ///
    /// # Note
    /// - Bitwise write one to clear
    pub int_status: RW<i2c_interrupt::I2cInterrupt>,
    /// 中断启用
    pub int_en: RW<i2c_interrupt::I2cInterrupt>,
}

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        /// SDA delay select
        ///
        /// Bits: `3..2`
        pub const fn sda_del_sel(&self) -> u8 {
            (self.0 & 0x0C) >> 2
        }
        pub const fn with_sda_del_sel(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x0C) | ((value as u8) << 2);
            self
        }

        /// Wakeup enable
        ///
        /// Bits: `5`
        pub const fn wkupen(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_wkupen(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// General-call enable
        ///
        /// Bits: `6`
        pub const fn gcen(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_gcen(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }

        /// I2C enable. Toggling this bit resets the core.
        ///
        /// Bits: `7`
        pub const fn i2cen(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_i2cen(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod command {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Command(u8);
    bitfield_reg!(Command, u8, 0x04);

    impl Command {
        /// 关闭时钟拉伸。写入时这个位必须被设为1。
        ///
        /// Bits: `2`
        pub const fn cksdis(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_cksdis(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// Bits: `3`
        pub const fn ack(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_ack(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// Bits: `4`
        pub const fn write(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_write(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// Bits: `5`
        pub const fn read(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_read(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// Bits: `6`
        pub const fn stop(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_stop(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }

        /// Bits: `7`
        pub const fn start(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_start(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
    }
}

pub mod br1 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Br1(u8);
    bitfield_reg!(Br1, u8, 0x00);

    impl Br1 {
        /// Prescale [9:8]
        ///
        /// Bits: `1..0`
        pub const fn prescale_h(&self) -> u8 {
            (self.0 & 0x03) >> 0
        }
        pub const fn with_prescale_h(mut self, value: u8) -> Self {
            self.0 = (self.0 & !0x03) | ((value as u8) << 0);
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
        /// Hardware general call
        ///
        /// Bits: `0`
        pub const fn hgc(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_hgc(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// Transmit/receive overflow or NACK
        ///
        /// Bits: `1`
        pub const fn troe(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_troe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// Transmit/receive ready
        ///
        /// Bits: `2`
        pub const fn trrdy(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_trrdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// Arbitration lost
        ///
        /// Bits: `3`
        pub const fn arbl(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_arbl(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }

        /// Slave read/write
        ///
        /// Bits: `4`
        pub const fn srw(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_srw(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// Received ACK
        ///
        /// Bits: `5`
        pub const fn rarc(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_rarc(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// Bus busy
        ///
        /// Bits: `6`
        pub const fn busy(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_busy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
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

pub mod i2c_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct I2cInterrupt(u8);
    bitfield_reg!(I2cInterrupt, u8, 0x00);

    impl I2cInterrupt {
        /// 收到通用广播
        ///
        /// Bits: `0`
        pub const fn irqhgc(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_irqhgc(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 发送/接收溢出或收到NACK
        ///
        /// Bits: `1`
        pub const fn irqtroe(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_irqtroe(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 发送/接收已准备好
        ///
        /// Bits: `2`
        pub const fn irqtrrdy(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_irqtrrdy(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 仲裁丢失
        ///
        /// Bits: `3`
        pub const fn irqarbl(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_irqarbl(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }
    }
}
