use crate::common::register::*;

#[repr(C)]
pub struct Uart {
    /// UART 数据。 写入以发送，读取以接收。
    pub data: RW<u8>,
    __: [u8; 3],
    /// UART 状态
    pub status: RO<status::Status>,
}

pub mod status {
    use crate::common::register::*;

    #[derive(Clone, Copy)]
    pub struct Status(u8);
    bitfield_reg!(Status, u8, 0);

    impl Status {
        /// 发送缓冲区未满
        ///
        /// Bits: `0`
        pub const fn tx_ready(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_tx_ready(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 接收缓冲区未空
        ///
        /// Bits: `1`
        pub const fn rx_end(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_rx_end(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 发送缓冲区已空
        ///
        /// Bits: `2`
        pub const fn tx_empty(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_tx_empty(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 接收缓冲区已满
        ///
        /// Bits: `3`
        pub const fn rx_full(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_rx_full(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }
    }
}
