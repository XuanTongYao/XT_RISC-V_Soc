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

pub mod control0 {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct Control0(u8);
    bitfield_reg!(Control0, u8, 0x00);

    impl Control0 {
        /// 时钟源选择
        ///
        /// Bits: `1`
        pub const fn clksel(&self) -> TimerClkSel {
            TimerClkSel::from_bits(self.0 >> 1)
        }
        pub const fn clksel_bits(&self) -> u8 {
            (self.0 & 0x02) >> 1
        }
        pub const fn with_clksel(mut self, value: TimerClkSel) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 用于设置时钟源的有效沿
        ///
        /// Bits: `2`
        pub const fn clkedge(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_clkedge(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 时钟预分频
        ///
        /// Bits: `5..3`
        pub const fn prescale(&self) -> TimerDivider {
            TimerDivider::from_bits(self.0 >> 3)
        }
        pub const fn prescale_bits(&self) -> u8 {
            (self.0 & 0x38) >> 3
        }
        pub const fn with_prescale(mut self, value: TimerDivider) -> Self {
            self.0 = (self.0 & !0x38) | ((value as u8) << 3);
            self
        }

        /// 启用外部复位信号
        ///
        /// Bits: `7`
        pub const fn rsten(&self) -> bool {
            ((self.0 & 0x80) >> 7) != 0
        }
        pub const fn with_rsten(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x80) | ((value as u8) << 7);
            self
        }
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
        /// 定时器/计数器模式
        ///
        /// Bits: `1..0`
        pub const fn tcm(&self) -> TimerCounterMode {
            TimerCounterMode::from_bits(self.0 >> 0)
        }
        pub const fn tcm_bits(&self) -> u8 {
            (self.0 & 0x03) >> 0
        }
        pub const fn with_tcm(mut self, value: TimerCounterMode) -> Self {
            self.0 = (self.0 & !0x03) | ((value as u8) << 0);
            self
        }

        /// 定时器输出模式
        ///
        /// Bits: `3..2`
        pub const fn ocm(&self) -> TimerOutputMode {
            TimerOutputMode::from_bits(self.0 >> 2)
        }
        pub const fn ocm_bits(&self) -> u8 {
            (self.0 & 0x0C) >> 2
        }
        pub const fn with_ocm(mut self, value: TimerOutputMode) -> Self {
            self.0 = (self.0 & !0x0C) | ((value as u8) << 2);
            self
        }

        /// 启用自动重装载
        ///
        /// Bits: `4`
        pub const fn tsel(&self) -> bool {
            ((self.0 & 0x10) >> 4) != 0
        }
        pub const fn with_tsel(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x10) | ((value as u8) << 4);
            self
        }

        /// 启用输入捕获
        ///
        /// Bits: `5`
        pub const fn icen(&self) -> bool {
            ((self.0 & 0x20) >> 5) != 0
        }
        pub const fn with_icen(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x20) | ((value as u8) << 5);
            self
        }

        /// 在总线访问下此字段无效
        ///
        /// Bits: `6`
        pub const fn sovfen(&self) -> bool {
            ((self.0 & 0x40) >> 6) != 0
        }
        pub const fn with_sovfen(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x40) | ((value as u8) << 6);
            self
        }
    }

    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerCounterMode {
        Watchdog = 0,
        ClearTimerOnCompareMatch = 1,
        FastPWM = 2,
        PhaseAndFrequencyCorrectPWM = 3,
    }

    impl TimerCounterMode {
        pub const MASK: u8 = 0x3;
        pub const RESET: Self = Self::Watchdog;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::Watchdog,
                1 => Self::ClearTimerOnCompareMatch,
                2 => Self::FastPWM,
                _ => Self::PhaseAndFrequencyCorrectPWM,
            }
        }
    }
    #[repr(u8)]
    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub enum TimerOutputMode {
        StaticLow = 0,
        Toggle = 1,
        SetClear = 2,
        ClearSet = 3,
    }

    impl TimerOutputMode {
        pub const MASK: u8 = 0x3;
        pub const RESET: Self = Self::StaticLow;
        pub const fn from_bits(bits: u8) -> Self {
            match bits & Self::MASK {
                0 => Self::StaticLow,
                1 => Self::Toggle,
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
        /// 暂停定时器
        ///
        /// Bits: `0`
        pub const fn wbpause(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_wbpause(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 重置定时器(必须等待至少两个周期后将该位手动恢复到0)
        ///
        /// Bits: `1`
        pub const fn wbreset(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_wbreset(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 非PWM模式强制输出，当定时器匹配或到达周期时
        ///
        /// Bits: `2`
        pub const fn wbforce(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_wbforce(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
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
        /// 溢出标志
        ///
        /// Bits: `0`
        pub const fn ovf(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_ovf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 输出匹配标志
        ///
        /// Bits: `1`
        pub const fn ocrf(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_ocrf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 输入事件标志
        ///
        /// Bits: `2`
        pub const fn icrf(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_icrf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }

        /// 置0标志
        ///
        /// Bits: `3`
        pub const fn btf(&self) -> bool {
            ((self.0 & 0x08) >> 3) != 0
        }
        pub const fn with_btf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x08) | ((value as u8) << 3);
            self
        }
    }
}

pub mod timer_interrupt {
    use crate::common::register::*;

    #[derive(Copy, Clone, Debug, PartialEq, Eq)]
    pub struct TimerInterrupt(u8);
    bitfield_reg!(TimerInterrupt, u8, 0x00);

    impl TimerInterrupt {
        /// 溢出
        ///
        /// Bits: `0`
        pub const fn irqovf(&self) -> bool {
            ((self.0 & 0x01) >> 0) != 0
        }
        pub const fn with_irqovf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x01) | ((value as u8) << 0);
            self
        }

        /// 输出匹配
        ///
        /// Bits: `1`
        pub const fn irqocrf(&self) -> bool {
            ((self.0 & 0x02) >> 1) != 0
        }
        pub const fn with_irqocrf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x02) | ((value as u8) << 1);
            self
        }

        /// 输入事件
        ///
        /// Bits: `2`
        pub const fn irqicrf(&self) -> bool {
            ((self.0 & 0x04) >> 2) != 0
        }
        pub const fn with_irqicrf(mut self, value: bool) -> Self {
            self.0 = (self.0 & !0x04) | ((value as u8) << 2);
            self
        }
    }
}
