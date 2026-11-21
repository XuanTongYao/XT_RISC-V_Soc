use crate::common::register::*;

#[repr(C)]
pub struct Flash {
    /// Flash 控制
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
            /// 复位连接，复位输入输出 FIFO 的相关逻辑。此位是电平敏感的。
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, wbce, with_wbce, 0x80, 7
            /// 开启 WISHBONE 总线到 Flash 逻辑的连接。每次执行命令前都必须设置此位，命令结束后必须清空此位。
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
            u8, bool, i2cact, 0x01, 0
            /// `wbce`启用时，主 I2C 接口与 Flash 逻辑主动通信。 I2C 拥有更高的优先级，将抢占任何现有的 WISHBONE 事务。
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, sspiact, 0x02, 1
            /// `wbce`启用时， SPI 接口与 Flash 逻辑主动通信。 SPI 拥有最高的优先级，将抢占任何现有的 WISHBONE/I2C 事务。
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, rxff, 0x04, 2
            /// 接收FIFO已满
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, rxfe, 0x08, 3
            /// 接收FIFO已空
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, txff, 0x10, 4
            /// 发送FIFO已满
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, txfe, 0x20, 5
            /// 发送FIFO已空
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, wbcact, 0x80, 7
            /// WISHBONE 总线到 Flash 逻辑的接口已激活
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
            /// 指示`status`寄存器的`i2cact`被设置
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, sspiact, with_sspiact, 0x02, 1
            /// 指示`status`寄存器的`sspiact`被设置
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
