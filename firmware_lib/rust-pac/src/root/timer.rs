use crate::common::register::*;

#[repr(C)]
pub struct Timer {
    pub control0: RW<control0::Control0>,
    pub control1: RW<control1::Control1>,
    /// TOP set low byte
    pub top_setl: WO<u8>,
    /// TOP set high byte
    pub top_seth: WO<u8>,
    /// COMPARE set low byte
    pub compare_setl: WO<u8>,
    /// COMPARE set high byte
    pub compare_seth: WO<u8>,
    pub control2: RW<control2::Control2>,
    /// Counter low byte
    pub counterl: RO<u8>,
    /// Counter high byte
    pub counterh: RO<u8>,
    /// TOP current value low byte
    pub topl: RO<u8>,
    /// TOP current value high byte
    pub toph: RO<u8>,
    /// COMPARE current value low byte
    pub comparel: RO<u8>,
    /// COMPARE current value high byte
    pub compareh: RO<u8>,
    /// Capture low byte
    pub capturel: RO<u8>,
    /// Capture high byte
    pub captureh: RO<u8>,
    /// # Note
    /// - All bits are cleared on write
    pub status: RW<status::Status>,
    /// 中断状态
    ///
    /// # Note
    /// - Bitwise write one to clear
    pub int_status: RW<timer_interrupt::TimerInterrupt>,
    /// 中断启用
    pub int_en: RW<timer_interrupt::TimerInterrupt>,
}

pub type InstanceTimer = RegisterBlock<Timer>;

pub mod control0 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control0(u8);
    bitfield_reg!(Control0, u8, 0x00);

    impl Control0 {
        bitfield_accessor!(
            u8, enum TimerClkSel, clksel, clksel_bits, with_clksel, 0x02, 1
            /// 时钟源选择
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, clkedge, with_clkedge, 0x04, 2
            /// 时钟源的有效沿 `true`为下降沿
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, enum TimerDivider, prescale, prescale_bits, with_prescale, 0x38, 3
            /// 时钟预分频
            ///
            /// Bits: `5..3`
        );

        bitfield_accessor!(
            u8, bool, rsten, with_rsten, 0x80, 7
            /// 启用外部复位信号
            ///
            /// Bits: `7`
        );
    }

    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerClkSel {
        ClockTree = 0,
        OnChipOsc = 1,
    }

    impl TimerClkSel {
        pub const MASK: u8 = 0x1;
        pub const RESET: Self = Self::ClockTree;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::ClockTree,
                _ => Self::OnChipOsc,
            }
        }
    }
    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerDivider {
        /// 关闭时钟
        DISABLED = 0,
        Div1 = 1,
        Div8 = 2,
        Div64 = 3,
        Div256 = 4,
        Div1024 = 5,
        _InvaildBits = 6,
    }

    impl TimerDivider {
        pub const MASK: u8 = 0x7;
        pub const RESET: Self = Self::DISABLED;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::DISABLED,
                1 => Self::Div1,
                2 => Self::Div8,
                3 => Self::Div64,
                4 => Self::Div256,
                5 => Self::Div1024,
                _ => Self::_InvaildBits,
            }
        }
    }
}

pub mod control1 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control1(u8);
    bitfield_reg!(Control1, u8, 0x00);

    impl Control1 {
        bitfield_accessor!(
            u8, enum TimerCounterMode, tcm, tcm_bits, with_tcm, 0x03, 0
            /// 定时器/计数器模式
            ///
            /// Bits: `1..0`
        );

        bitfield_accessor!(
            u8, enum TimerOutputMode, ocm, ocm_bits, with_ocm, 0x0C, 2
            /// 输出信号模式
            ///
            /// Bits: `3..2`
        );

        bitfield_accessor!(
            u8, bool, tsel, with_tsel, 0x10, 4
            /// 启用Top寄存器自动装载
            ///
            /// Bits: `4`
        );

        bitfield_accessor!(
            u8, bool, icen, with_icen, 0x20, 5
            /// 启用输入捕获
            ///
            /// Bits: `5`
        );

        bitfield_accessor!(
            u8, bool, sovfen, with_sovfen, 0x40, 6
            /// 在总线访问下此字段无效
            ///
            /// Bits: `6`
        );
    }

    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerCounterMode {
        Watchdog = 0,
        ClearTimerOnTop = 1,
        FastPWM = 2,
        PhaseAndFrequencyCorrectPWM = 3,
    }

    impl TimerCounterMode {
        pub const MASK: u8 = 0x3;
        pub const RESET: Self = Self::Watchdog;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::Watchdog,
                1 => Self::ClearTimerOnTop,
                2 => Self::FastPWM,
                _ => Self::PhaseAndFrequencyCorrectPWM,
            }
        }
    }
    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerOutputMode {
        StaticLow = 0,
        /// 上溢出时翻转输出电平(仅在非PWM模式下有效)
        ToggleOnTop = 1,
        /// 快速PWM模式: 比较匹配输出`1`，上溢出输出`0`。
        ///
        /// 相位修正PWM模式: 只检测比较匹配，计数器递增时输出`0`，计数器递减时输出`1`。
        /// # Note
        /// 在非PWM模式下无效
        SetClear = 2,
        /// 快速PWM模式: 比较匹配输出`0`，上溢出输出`1`。
        ///
        /// 相位修正PWM模式: 只检测比较匹配，计数器递增时输出`1`，计数器递减时输出`0`。
        /// # Note
        /// 在非PWM模式下无效
        ClearSet = 3,
    }

    impl TimerOutputMode {
        pub const MASK: u8 = 0x3;
        pub const RESET: Self = Self::StaticLow;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::StaticLow,
                1 => Self::ToggleOnTop,
                2 => Self::SetClear,
                _ => Self::ClearSet,
            }
        }
    }
}

pub mod control2 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control2(u8);
    bitfield_reg!(Control2, u8, 0x00);

    impl Control2 {
        bitfield_accessor!(
            u8, bool, wbpause, with_wbpause, 0x01, 0
            /// 暂停计数器
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, wbreset, with_wbreset, 0x02, 1
            /// 重置计数器为`0`，写入`1`生效一次
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, wbforce, with_wbforce, 0x04, 2
            /// 强制触发比较匹配或上溢出(仅在非PWM模式有效)，写入`1`生效一次
            ///
            /// Bits: `2`
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
            u8, bool, ovf, with_ovf, 0x01, 0
            /// 上溢出标志
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, ocrf, with_ocrf, 0x02, 1
            /// 比较匹配标志
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, icrf, with_icrf, 0x04, 2
            /// 输入事件标志
            ///
            /// Bits: `2`
        );

        bitfield_accessor!(
            u8, bool, btf, with_btf, 0x08, 3
            /// (0)下溢出标志
            ///
            /// Bits: `3`
        );
    }
}

pub mod timer_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct TimerInterrupt(u8);
    bitfield_reg!(TimerInterrupt, u8, 0x00);

    impl TimerInterrupt {
        bitfield_accessor!(
            u8, bool, irqovf, with_irqovf, 0x01, 0
            /// 上溢出
            ///
            /// Bits: `0`
        );

        bitfield_accessor!(
            u8, bool, irqocrf, with_irqocrf, 0x02, 1
            /// 比较匹配
            ///
            /// Bits: `1`
        );

        bitfield_accessor!(
            u8, bool, irqicrf, with_irqicrf, 0x04, 2
            /// 输入事件
            ///
            /// Bits: `2`
        );
    }
}
