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

pub type InstanceSpi = RegisterBlock<Spi>;

pub mod control0 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control0(u8);
    bitfield_reg!(Control0, u8, 0x00);

    impl Control0 {
        bitfield_accessor!(
            u8, u8, tlead_xcnt, with_tlead_xcnt, 0x07, 0
            /// 前导延迟周期
            ///
            /// Bits: `2..0`
        );

        bitfield_accessor!(
            u8, u8, ttrail_xcnt, with_ttrail_xcnt, 0x38, 3
            /// 尾随延迟周期
            ///
            /// Bits: `5..3`
        );

        bitfield_accessor!(
            u8, u8, tidle_xcnt, with_tidle_xcnt, 0xC0, 6
            /// 空闲延迟周期
            ///
            /// Bits: `7..6`
        );
    }
}

pub mod control1 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control1(u8);
    bitfield_reg!(Control1, u8, 0x00);

    impl Control1 {
        bitfield_accessor!(
            u8, bool, txedge, with_txedge, 0x10, 4
            /// Transmit edge
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, wkupen_cfg, with_wkupen_cfg, 0x20, 5
            /// Wakeup enable (config)
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, wkupen_user, with_wkupen_user, 0x40, 6
            /// Wakeup enable (user)
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, spe, with_spe, 0x80, 7
            /// SPI enable
            ///
            /// Bits: `7`
        );
    }
}

pub mod control2 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control2(u8);
    bitfield_reg!(Control2, u8, 0x00);

    impl Control2 {
        bitfield_accessor!(
            u8, bool, lsbf, with_lsbf, 0x01, 0
            /// LSB first
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, cpha, with_cpha, 0x02, 1
            /// Clock phase (second edge)
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, cpol, with_cpol, 0x04, 2
            /// Clock polarity (active low)
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, mcsh, with_mcsh, 0x40, 6
            /// Master holds chip select low even if there is no data to be transmitted
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, mstr, with_mstr, 0x80, 7
            /// Master mode
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
            u8, bool, mdf, with_mdf, 0x01, 0
            /// Mode fault
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, roe, with_roe, 0x02, 1
            /// Receive overflow
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, rrdy, with_rrdy, 0x08, 3
            /// Receive ready
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, trdy, with_trdy, 0x10, 4
            /// Transmit ready
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, tip, with_tip, 0x80, 7
            /// Transfer in progress
            ///
            /// Bits: `7`
        );
    }
}

pub mod spi_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct SpiInterrupt(u8);
    bitfield_reg!(SpiInterrupt, u8, 0x00);

    impl SpiInterrupt {
        bitfield_accessor!(
            u8, bool, irqmdf, with_irqmdf, 0x01, 0
            /// 模式错误，在主机模式时自身片选被拉低
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, irqroe, with_irqroe, 0x02, 1
            /// 接收溢出
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, irqrrdy, with_irqrrdy, 0x08, 3
            /// 接收就绪
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, irqtrdy, with_irqtrdy, 0x10, 4
            /// 发送就绪
            ///
            /// Bits: `4`
        );
    }
}
