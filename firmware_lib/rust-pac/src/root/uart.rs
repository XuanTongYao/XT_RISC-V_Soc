use crate::common::register::*;

#[repr(C)]
pub struct Uart {
    /// UART 数据。 写入以发送，读取以接收。
    pub data: RW<u8>,
    __: [u8; 3],
    /// UART 状态
    pub status: RO<status::Status>,
}

pub type InstanceUart = RegisterBlock<Uart>;

pub mod status {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Status(u8);
    bitfield_reg!(Status, u8, 0x00);

    impl Status {
        bitfield_accessor!(
            u8, bool, tx_ready, with_tx_ready, 0x01, 0
            /// 发送缓冲区未满
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, rx_end, with_rx_end, 0x02, 1
            /// 接收缓冲区未空
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, tx_empty, with_tx_empty, 0x04, 2
            /// 发送缓冲区已空
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, rx_full, with_rx_full, 0x08, 3
            /// 接收缓冲区已满
            ///
            /// Bits: `3`
        );
    }
}
