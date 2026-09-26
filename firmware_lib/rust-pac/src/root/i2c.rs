use crate::common::register::*;

#[repr(C)]
pub struct I2c {
    /// 写入会导致I2C复位.
    pub control: RW<control::Control>,
    pub command: RW<command::Command>,
    /// 时钟预分频低8位。 预分频值共有10位。
    ///
    /// - **主机**模式时，范围 `[0,1023]`
    /// - **从机**模式时，范围 `[0,512]`
    pub br0: RW<u8>,
    /// 时钟预分频高2位。 写入会导致I2C复位。
    pub br1: RW<br1::Br1>,
    pub tx_data: WO<u8>,
    pub status: RO<status::Status>,
    pub general_call_data: RO<u8>,
    pub rx_data: RO<u8>,
    /// 中断状态
    ///
    /// # Note
    /// - Bitwise write one to clear
    pub int_status: RW<i2c_interrupt::I2cInterrupt>,
    /// 中断启用
    pub int_en: RW<i2c_interrupt::I2cInterrupt>,
}

pub type InstanceI2c = RegisterBlock<I2c>;

pub mod control {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control(u8);
    bitfield_reg!(Control, u8, 0x00);

    impl Control {
        bitfield_accessor!(
            u8, u8, sda_del_sel, with_sda_del_sel, 0x0C, 2
            /// SDA 输出延迟
            /// - 00: 300 ns (min) 300 ns + 2000/[wb_clk_i frequency in MHz] (max)
            /// - 01: 150 ns (min) 150 ns + 2000/[wb_clk_i frequency in MHz] (max)
            /// - 10: 75 ns (min) 75 ns + 2000/[wb_clk_i frequency in MHz] (max)
            /// - 11: 0 ns (min) 0 ns + 2000/[wb_clk_i frequency in MHz] (max)
            ///
            /// Bits: `3..2`
        );

        bitfield_accessor!(
            u8, bool, wkupen, with_wkupen, 0x20, 5
            /// Wakeup enable
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, gcen, with_gcen, 0x40, 6
            /// 启用通用广播(General Call)，仅在从机时有效
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, i2cen, with_i2cen, 0x80, 7
            /// I2C启用
            ///
            /// Bits: `7`
        );
    }
}

pub mod command {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Command(u8);
    bitfield_reg!(Command, u8, 0x04);

    impl Command {
        bitfield_accessor!(
            u8, bool, cksdis, with_cksdis, 0x04, 2
            /// 关闭时钟拉伸。写入时这个位必须被设为`1`。
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, ack, with_ack, 0x08, 3
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, write, with_write, 0x10, 4
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, read, with_read, 0x20, 5
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, stop, with_stop, 0x40, 6
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, start, with_start, 0x80, 7
            /// Bits: `7`
        );
    }
}

pub mod br1 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Br1(u8);
    bitfield_reg!(Br1, u8, 0x00);

    impl Br1 {
        bitfield_accessor!(
            u8, u8, prescale_h, with_prescale_h, 0x03, 0
            /// Bits: `1..0`
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
            u8, bool, hgc, with_hgc, 0x01, 0
            /// 收到通用广播
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, troe, with_troe, 0x02, 1
            /// 发送/接收溢出或在主机模式收到NACK
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, trrdy, with_trrdy, 0x04, 2
            /// 发送/接收就绪
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, arbl, with_arbl, 0x08, 3
            /// 仲裁丢失
            ///
            /// Bits: `3`
        );

        bitfield_accessor!(
            u8, bool, srw, with_srw, 0x10, 4
            /// - 1: 主机接收，从机发送
            /// - 0: 从机接收，主机发送
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, rarc, with_rarc, 0x20, 5
            /// 收到的 ACK 位.
            ///
            /// - `true`: NACK
            /// - `false`: ACK
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, busy, with_busy, 0x40, 6
            /// 总线忙
            ///
            /// Bits: `6`
        );

        bitfield_accessor!(
            u8, bool, tip, with_tip, 0x80, 7
            /// 传输进行中
            ///
            /// Bits: `7`
        );
    }
}

pub mod i2c_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct I2cInterrupt(u8);
    bitfield_reg!(I2cInterrupt, u8, 0x00);

    impl I2cInterrupt {
        bitfield_accessor!(
            u8, bool, irqhgc, with_irqhgc, 0x01, 0
            /// 收到通用广播
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, irqtroe, with_irqtroe, 0x02, 1
            /// 发送/接收溢出或收到NACK
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, irqtrrdy, with_irqtrrdy, 0x04, 2
            /// 发送/接收已准备好
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, irqarbl, with_irqarbl, 0x08, 3
            /// 仲裁丢失
            ///
            /// Bits: `3`
        );
    }
}
