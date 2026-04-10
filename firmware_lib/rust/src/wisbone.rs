//! WISHBONE总线外设，主要是FPGA芯片的嵌入式硬核

use crate::common::Peripheral;
const DOMAIN_WISHBONE_BASE: usize = crate::common::domain_base(3);
// const PLL0_OFFSET: usize = 0x00;
// const PLL1_OFFSET: usize = 0x20;
const I2C_PRIMARY_OFFSET: usize = 0x40;
const I2C_SECONDARY_OFFSET: usize = 0x4A;
const SPI_OFFSET: usize = 0x54;
const TIMER_OFFSET: usize = 0x5E;
const FLASH_OFFSET: usize = 0x70;
const EFB_INT_SOURCE_OFFSET: usize = 0x76;
const fn lb_base(offset: usize) -> usize {
    DOMAIN_WISHBONE_BASE + offset
}

pub const FREQ_HZ: u32 = crate::rv_core::CORE_FREQ_HZ;

macro_rules! get_u16_from_2_u8 {
    ($(#[$doc:meta])* $name:ident, [$reg_h:ident, $reg_l:ident]) => {
        $(#[$doc])*
        #[inline(always)]
        pub fn $name(&self) -> u16 {
            let low = self.reg().$reg_l.read() as u16;
            ((self.reg().$reg_h.read() as u16) << 8) | low
        }
    };
}

pub mod regs {
    use bitfield_struct::{bitenum, bitfield};
    use volatile_register::{RO, RW, WO};

    // #[repr(C)]
    // pub struct PLL {
    //     pub divfbk_fracl: RW<u8>,
    //     pub divfbk_frach: RW<u8>,
    //     pub loadreg_del_a: RW<PllReg2_9>,
    //     pub pllpdn_del_b: RW<PllReg2_9>,
    //     pub wbreset_del_c: RW<PllReg2_9>,
    //     pub use_desi_del_d: RW<PllReg2_9>,
    //     pub refin_reset_div_a: RW<PllReg2_9>,
    //     pub pllrst_ena_div_b: RW<PllReg2_9>,
    //     pub mrst_ena_div_c: RW<PllReg2_9>,
    //     pub stdby_div_d: RW<PllReg2_9>,
    // }

    // #[bitfield(u8)]
    // pub struct PllReg2_9 {
    //     /// del或者div
    //     #[bits(7)]
    //     pub del_div: u8,
    //     /// 该位由具体寄存器决定
    //     pub f: bool,
    // }

    #[repr(C)]
    pub struct I2C {
        /// 写入会导致I2C复位
        pub control: RW<I2cControl>,
        pub command: RW<I2cCommand>,
        pub br0: RW<u8>,
        /// 写入会导致I2C复位
        pub br1: RW<u8>,
        pub tx_data: WO<u8>,
        pub status: RO<I2cStatus>,
        pub general_call: RO<u8>,
        pub rx_data: RO<u8>,
        /// 写1清零
        pub int_status: RW<I2cInterrupt>,
        pub int_en: RW<I2cInterrupt>,
    }

    #[bitfield(u8)]
    pub struct I2cControl {
        #[bits(2)]
        __: u8,
        #[bits(2)]
        pub sda_del_sel: u8,
        __: bool,
        pub wkupen: bool,
        pub gcen: bool,
        pub i2cen: bool,
    }

    #[bitfield(u8)]
    pub struct I2cCommand {
        #[bits(2)]
        __: u8,
        pub cksdis: bool,
        pub ack: bool,
        pub wr: bool,
        pub rd: bool,
        pub sto: bool,
        pub sta: bool,
    }

    #[bitfield(u8)]
    pub struct I2cStatus {
        pub hgc: bool,
        pub troe: bool,
        pub trrdy: bool,
        pub arbl: bool,
        pub srw: bool,
        pub rarc: bool,
        pub busy: bool,
        pub tip: bool,
    }

    #[bitfield(u8)]
    pub struct I2cInterrupt {
        /// 收到通用广播
        pub irqhgc: bool,
        /// 发送/接收溢出或收到NACK
        pub irqtroe: bool,
        /// 发送/接收已准备好
        pub irqtrrdy: bool,
        /// 仲裁丢失
        pub irqarbl: bool,
        #[bits(4)]
        __: u8,
    }

    #[repr(C)]
    pub struct SPI {
        pub control0: RW<SpiControl0>,
        pub control1: RW<SpiControl1>,
        pub control2: RW<SpiControl2>,
        pub clock_prescale: RW<u8>,
        /// # Warning
        /// 设置片选会使SPI复位
        pub cs: RW<u8>,
        pub tx_data: WO<u8>,
        pub status: RO<SpiStatus>,
        pub rx_data: RO<u8>,
        /// 写1清零
        pub int_status: RW<SpiInterrupt>,
        pub int_en: RW<SpiInterrupt>,
    }

    /// 所有延迟周期的精度为0.5个SCK周期，最短0.5
    #[bitfield(u8)]
    pub struct SpiControl0 {
        /// 前导延迟周期
        #[bits(3)]
        pub tlead_xcnt: u8,
        /// 尾随延迟周期
        #[bits(3)]
        pub ttrail_xcnt: u8,
        /// 空闲延迟周期
        #[bits(2)]
        pub tidle_xcnt: u8,
    }

    #[bitfield(u8)]
    pub struct SpiControl1 {
        #[bits(4)]
        __: u8,
        pub txedge: bool,
        pub wkupen_cfg: bool,
        pub wkupen_user: bool,
        pub spe: bool,
    }

    #[bitfield(u8)]
    pub struct SpiControl2 {
        pub lsbf: bool,
        pub cpha: bool,
        pub cpol: bool,
        #[bits(2)]
        __: u8,
        /// 专用扩展(无用)
        #[bits(access=None)]
        sdbre: bool,
        /// 主机永久拉低片选信号
        pub mcsh: bool,
        pub mstr: bool,
    }

    #[bitfield(u8)]
    pub struct SpiStatus {
        pub mdf: bool,
        pub roe: bool,
        __: bool,
        pub rrdy: bool,
        pub trdy: bool,
        #[bits(2)]
        __: u8,
        pub tip: bool,
    }

    #[bitfield(u8)]
    pub struct SpiInterrupt {
        /// 模式错误，在主机模式时自身片选被拉低
        pub irqmdf: bool,
        /// 接收溢出
        pub irqroe: bool,
        __: bool,
        /// 接收就绪
        pub irqrrdy: bool,
        /// 发送就绪
        pub irqtrdy: bool,
        #[bits(3)]
        __: u8,
    }

    #[repr(C)]
    pub struct Timer {
        pub control0: RW<TimerControl0>,
        pub control1: RW<TimerControl1>,
        pub top_setl: WO<u8>,
        pub top_seth: WO<u8>,
        pub compare_setl: WO<u8>,
        pub compare_seth: WO<u8>,
        pub control2: RW<TimerControl2>,
        pub counterl: RO<u8>,
        pub counterh: RO<u8>,
        pub topl: RO<u8>,
        pub toph: RO<u8>,
        pub comparel: RO<u8>,
        pub compareh: RO<u8>,
        pub capturel: RO<u8>,
        pub captureh: RO<u8>,
        /// 执行写入将清空全部位
        pub status: RW<TimerStatus>,
        /// 写1清零
        pub int_status: RW<TimerInterrupt>,
        pub int_en: RW<TimerInterrupt>,
    }

    #[bitfield(u8)]
    pub struct TimerControl0 {
        __: bool,
        #[bits(1)]
        pub clksel: TimerClkSel,
        pub clkedge: bool,
        #[bits(3)]
        pub prescale: TimerDivider,
        __: bool,
        pub rsten: bool,
    }
    #[bitenum]
    #[repr(u8)]
    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum TimerClkSel {
        #[fallback]
        ClockTree,
        OnChipOsc,
    }
    #[bitenum]
    #[repr(u8)]
    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum TimerDivider {
        #[fallback]
        DISABLED,
        Div1,
        Div8,
        Div64,
        Div256,
        Div1024,
    }

    #[bitfield(u8)]
    pub struct TimerControl1 {
        #[bits(2)]
        pub tcm: TimerCounterMode,
        #[bits(2)]
        pub ocm: TimerOutputMode,
        pub tsel: bool,
        pub icen: bool,
        /// 在总线访问下无效
        pub sovfen: bool,
        __: bool,
    }
    #[bitenum]
    #[repr(u8)]
    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum TimerCounterMode {
        #[fallback]
        Watchdog,
        ClearTimerOnCompareMatch,
        FastPWM,
        PhaseAndFrequencyCorrectPWM,
    }
    #[bitenum]
    #[repr(u8)]
    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum TimerOutputMode {
        #[fallback]
        StaticLow,
        Toggle,
        SetClear,
        ClearSet,
    }

    #[bitfield(u8)]
    pub struct TimerControl2 {
        pub wbpause: bool,
        pub wbreset: bool,
        pub wbforce: bool,
        #[bits(5)]
        __: u8,
    }
    #[bitfield(u8)]
    pub struct TimerStatus {
        /// 溢出标志
        pub ovf: bool,
        /// 输出匹配标志
        pub ocrf: bool,
        /// 输入事件标志
        pub icrf: bool,
        /// 置0标志
        pub btf: bool,
        #[bits(4)]
        __: u8,
    }

    #[bitfield(u8)]
    pub struct TimerInterrupt {
        /// 溢出
        pub irqovf: bool,
        /// 输出匹配
        pub irqocrf: bool,
        /// 输入事件
        pub irqicrf: bool,
        #[bits(5)]
        __: u8,
    }

    #[repr(C)]
    pub struct Flash {
        pub control: RW<FlashControl>,
        pub write_data: WO<u8>,
        pub status: RO<FlashStatus>,
        pub read_data: RO<u8>,
        /// 写1清零
        pub int_status: RW<FlashInterrupt>,
        pub int_en: RW<FlashInterrupt>,
    }

    #[bitfield(u8)]
    pub struct FlashControl {
        #[bits(6)]
        __: u8,
        pub rste: bool,
        pub wbce: bool,
    }
    #[bitfield(u8)]
    pub struct FlashStatus {
        #[bits(6)]
        pub flags: FlashInterrupt,
        __: bool,
        /// WB总线到配置(FPGA配置)接口激活(慎用！！！)
        pub wbcact: bool,
    }
    #[bitfield(u8)]
    pub struct FlashInterrupt {
        /// I2C激活
        pub i2cact: bool,
        /// SPI激活
        pub sspiact: bool,
        /// 接收FIFO已满
        pub rxff: bool,
        /// 接收FIFO已空
        pub rxfe: bool,
        /// 发送FIFO已满
        pub txff: bool,
        /// 发送FIFO已空
        pub txfe: bool,
        #[bits(2)]
        __: u8,
    }

    #[bitfield(u8)]
    pub struct EFBInterruptSource {
        pub i2c1: bool,
        pub i2c2: bool,
        pub spi: bool,
        pub tc: bool,
        pub ufmcfg: bool,
        #[bits(3)]
        __: u8,
    }
}

/// 不建议直接使用该类，来完成传输事务
pub type I2cInner = Peripheral<regs::I2C, 0>;
impl I2cInner {
    pub const PRIMARY: Self = unsafe { Self::from_ptr(lb_base(I2C_PRIMARY_OFFSET) as _) };
    pub const SECONDARY: Self = unsafe { Self::from_ptr(lb_base(I2C_SECONDARY_OFFSET) as _) };
    pub const PRESCALE_MASK: u16 = 0x3FF;

    crate::get_value!(status, status, regs::I2cStatus);
    crate::get_value!(general_call, general_call, u8);
    crate::getset_value!(int_status, int_status, regs::I2cInterrupt);
    crate::getset_value!(int_en, int_en, regs::I2cInterrupt);

    get_u16_from_2_u8!(prescale, [br1, br0]);

    /// 设置预分频为 `div`，实际频率为`WISHBONE/(div*4)`
    /// - **主机**模式时，范围 `[0,1023]`
    /// - **从机**模式时，范围 `[0,512]`
    /// # Warning
    /// 重设预分频会使I2C复位
    #[inline(always)]
    pub fn set_prescale(&mut self, div: u16) {
        unsafe {
            self.reg().br0.write(div as u8);
            self.reg().br1.write((div >> 8) as u8);
        }
    }

    pub fn reset(&mut self) {
        unsafe {
            self.reg().control.modify(|con| con.with_i2cen(false));
            // 原始C代码，出于未知原因在这里延迟了50us，如果出现问题请加回来
            self.reg().control.modify(|con| con.with_i2cen(true));
        }
    }

    /// 启动传输并进入**写入模式**\
    /// `delay_cycles`延迟的时间必须为(0,6)个I2C时钟周期
    #[inline]
    pub fn master_start_transmission_block(&mut self, addr: u8, delay_cycles: u32) {
        unsafe {
            self.reg().tx_data.write(addr & 0xFE); // `& 0xFE`表示写操作，I2C协议决定的
            self.reg().command.write(0x94.into());
            crate::rv_core::delay(delay_cycles); // 等(0,6)个I2C时钟周期
        }
    }

    /// 从**写入模式**切换为**读取模式**\
    /// 必须处于**写入模式**中才能调用此函数
    pub fn master_into_read_block(&mut self, addr: u8) {
        unsafe {
            self.reg().tx_data.write(addr | 0x01); // `| 0x01`表示读操作，I2C协议决定的
            self.reg().command.write(0x94.into());
            while !self.reg().status.read().srw() {}
            self.reg().command.write(0x24.into());
        }
    }

    /// 必须处于**写入模式**中才能调用此函数\
    /// `delay_cycles`延迟的时间必须为(0,6)个I2C时钟周期
    #[inline]
    pub fn master_write_byte_block(&mut self, byte: u8, delay_cycles: u32) {
        unsafe {
            self.reg().tx_data.write(byte);
            self.reg().command.write(0x14.into());
            crate::rv_core::delay(delay_cycles); // 等(0,6)个I2C时钟周期
        }
    }

    /// 必须处于**写入模式**中才能调用此函数\
    /// `delay_cycles_per_byte`延迟的时间必须为(0,6)个I2C时钟周期
    pub fn master_write_block(&mut self, data: &[u8], delay_cycles_per_byte: u32) {
        for byte in data {
            self.master_write_byte_block(*byte, delay_cycles_per_byte);
        }
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`master_finish_read_block`来获取
    #[inline]
    pub fn master_read_byte_block(&mut self) -> u8 {
        while !self.reg().status.read().trrdy() {}
        self.reg().rx_data.read()
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`master_finish_read_block`来获取
    pub fn master_read_into_block(&mut self, buffer: &mut [u8]) {
        for byte in buffer {
            *byte = self.master_read_byte_block();
        }
    }

    /// 从**写入模式**结束传输\
    /// 必须处于**写入模式**中才能调用此函数
    #[inline(always)]
    pub fn master_finish_write(&mut self) {
        unsafe { self.reg().command.write(0x44.into()) }
    }

    /// 从**读取模式**结束传输\
    /// 会返回最后一个读取到的字节\
    /// `delay_cycles`延迟的时间必须为(2,7)个I2C时钟周期
    pub fn master_finish_read_block(&mut self, delay_cycles: u32) -> u8 {
        unsafe {
            crate::rv_core::delay(delay_cycles); // 等(2,7)个I2C时钟周期
            self.reg().command.write(0x6C.into());
            let last_byte = self.master_read_byte_block();
            self.reg().command.write(0x04.into());
            last_byte
        }
    }
}

pub struct I2C {
    pub inner: I2cInner,
    write_delay_cycles: u16,
    read_delay_cycles: u16,
}

impl I2C {
    #[inline(always)]
    pub fn new_primary() -> Self {
        Self::new(I2cInner::PRIMARY)
    }

    #[inline(always)]
    pub fn new_secondary() -> Self {
        Self::new(I2cInner::SECONDARY)
    }

    fn new(inner: I2cInner) -> Self {
        let prescale = inner.prescale();
        Self {
            inner,
            write_delay_cycles: prescale,
            read_delay_cycles: prescale * 3,
        }
    }

    #[inline(always)]
    pub fn prescale(&self) -> u16 {
        self.inner.prescale()
    }

    /// 设置预分频为 `div`，实际频率为`WISHBONE/(div*4)`
    /// - **主机**模式时，范围 `[0,1023]`
    /// - **从机**模式时，范围 `[0,512]`
    /// # Warning
    /// 重设预分频会使I2C复位
    #[inline]
    pub fn set_prescale(&mut self, div: u16) {
        let div = div & I2cInner::PRESCALE_MASK;
        self.inner.set_prescale(div);
        self.write_delay_cycles = div;
        self.read_delay_cycles = div * 3;
    }

    #[inline(always)]
    pub fn reset(&mut self) {
        self.inner.reset()
    }

    /// 启动传输并进入**写入模式**
    #[inline(always)]
    pub fn master_start_transmission_block(&mut self, addr: u8) {
        self.inner
            .master_start_transmission_block(addr, self.write_delay_cycles as u32)
    }

    /// 从**写入模式**切换为**读取模式**\
    /// 必须处于**写入模式**中才能调用此函数
    #[inline(always)]
    pub fn master_into_read_block(&mut self, addr: u8) {
        self.inner.master_into_read_block(addr)
    }

    /// 必须处于**写入模式**中才能调用此函数
    #[inline(always)]
    pub fn master_write_byte_block(&mut self, byte: u8) {
        self.inner
            .master_write_byte_block(byte, self.write_delay_cycles as u32)
    }

    /// 必须处于**写入模式**中才能调用此函数
    #[inline(always)]
    pub fn master_write_block(&mut self, data: &[u8]) {
        self.inner
            .master_write_block(data, self.write_delay_cycles as u32)
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`master_finish_read_block`来获取
    #[inline(always)]
    pub fn master_read_byte_block(&mut self) -> u8 {
        self.inner.master_read_byte_block()
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`master_finish_read_block`来获取
    #[inline(always)]
    pub fn master_read_into_block(&mut self, buffer: &mut [u8]) {
        self.inner.master_read_into_block(buffer)
    }

    /// 从**写入模式**结束传输\
    /// 必须处于**写入模式**中才能调用此函数
    #[inline(always)]
    pub fn master_finish_write(&mut self) {
        self.inner.master_finish_write()
    }

    /// 从**读取模式**结束传输\
    /// 会返回最后一个读取到的字节
    #[inline(always)]
    pub fn master_finish_read_block(&mut self) -> u8 {
        self.inner
            .master_finish_read_block(self.read_delay_cycles as u32)
    }
}

pub type SPI = Peripheral<regs::SPI, { lb_base(SPI_OFFSET) }>;
impl SPI {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    crate::getset_field!(master_mode, control2, mstr, bool);
    crate::getset_field!(polarity_active_low, control2, cpol, bool);
    crate::getset_field!(phase_second_edge, control2, cpha, bool);
    crate::getset_field!(lsb_first, control2, lsbf, bool);

    crate::getset_value!(cs, cs, u8);

    crate::get_value!(
        /// 获取预分频`div`，实际频率为`WISHBONE/(div+1)`
        prescale, clock_prescale, u8);

    /// 设置预分频为 `div` 范围 `[1,63]`，实际频率为`WISHBONE/(div+1)`
    /// # Warning
    /// 重设预分频会使SPI复位
    #[inline(always)]
    pub fn set_prescale(&mut self, div: u8) {
        if div != 0 {
            unsafe { self.reg().clock_prescale.write(div) }
        }
    }

    pub fn master_start_rw_block(&mut self, byte: u8) -> u8 {
        unsafe {
            self.reg().control2.write(0xC0.into());
            while !self.reg().status.read().trdy() {}
            self.master_rw_byte_block(byte)
        }
    }

    /// 调用`master_start_rw_block`后才能使用此函数执行读写操作
    #[inline]
    pub fn master_rw_byte_block(&mut self, byte: u8) -> u8 {
        unsafe { self.reg().tx_data.write(byte) }
        while !self.reg().status.read().rrdy() {}
        self.reg().rx_data.read()
    }

    /// 调用`master_start_rw_block`后才能使用此函数
    #[inline]
    pub fn master_finish_rw_block(&mut self) {
        unsafe { self.reg().control2.write(0x80.into()) }
        while self.reg().status.read().tip() {}
    }

    pub fn slave_restart_rw_block(&mut self, byte0: u8, byte1: u8) -> u8 {
        let reg = self.reg();
        unsafe {
            reg.control2.write(0x00.into());
            while reg.status.read().tip() {}
            reg.rx_data.read();
            reg.rx_data.read(); // 丢弃2字节
            reg.tx_data.write(byte0);
            // IDLE
            while !reg.status.read().tip() {}
            reg.tx_data.write(byte1);
            while !reg.status.read().rrdy() {}
            reg.rx_data.read()
        }
    }

    /// 调用`slave_restart_rw_block`后才能使用此函数执行读写操作
    pub fn slave_rw_byte_block(&mut self, next_byte: u8) -> u8 {
        let reg = self.reg();
        unsafe {
            while !reg.status.read().trdy() {}
            reg.tx_data.write(next_byte);
            while !reg.status.read().rrdy() {}
            reg.rx_data.read()
        }
    }
}

pub type Timer = Peripheral<regs::Timer, { lb_base(TIMER_OFFSET) }>;
pub use regs::{TimerClkSel, TimerCounterMode, TimerDivider, TimerOutputMode};
impl Timer {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };
    get_u16_from_2_u8!(top, [toph, topl]);
    get_u16_from_2_u8!(compare, [compareh, comparel]);
    get_u16_from_2_u8!(counter, [counterh, counterl]);
    get_u16_from_2_u8!(capture, [captureh, capturel]);

    #[inline(always)]
    pub fn set_top(&mut self, value: u16) {
        unsafe {
            self.reg().top_setl.write(value as u8);
            self.reg().top_seth.write((value >> 8) as u8);
        }
    }
    #[inline(always)]
    pub fn set_compare(&mut self, value: u16) {
        unsafe {
            self.reg().compare_setl.write(value as u8);
            self.reg().compare_seth.write((value >> 8) as u8);
        }
    }

    crate::getset_value!(control0, control0, regs::TimerControl0);
    crate::getset_value!(control1, control1, regs::TimerControl1);

    crate::getset_field!(clk_source, control0, clksel, TimerClkSel);
    crate::getset_field!(
        /// 用于设置时钟源的有效沿
        active_negedge, control0, clkedge, bool);
    crate::getset_field!(prescale, control0, prescale, TimerDivider);
    crate::getset_field!(reset_signal_enabled, control0, rsten, bool);

    crate::getset_field!(counter_mode, control1, tcm, TimerCounterMode);
    crate::getset_field!(output_mode, control1, ocm, TimerOutputMode);
    crate::getset_field!(
        /// 启用自动重装载
        autoload, control1, tsel, bool);
    crate::getset_field!(
        /// 启用输入捕获
        input, control1, icen, bool);

    crate::getset_field!(paused, control2, wbpause, bool);
    crate::getset_field!(
        /// 重置计时器(必须等待至少两个周期后将该位手动恢复到0)
        reseted, control2, wbreset, bool);
    crate::getset_field!(
        /// 非PWM模式强制输出，当计时器匹配或到达周期时
        output_in_non_pwm, control2, wbforce, bool);
}

pub type Flash = Peripheral<regs::Flash, { lb_base(FLASH_OFFSET) }>;
pub enum FlashBuffer<'a> {
    Read(&'a mut [u8]),
    Write(&'a [u8]),
}

macro_rules! flash_write {
    ($flash:ident, $($byte:expr),+) => {
        unsafe {
            $( $flash.reg().write_data.write($byte); )*
        }
    };
}
impl Flash {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    pub const TOTAL_PAGE: usize = 767;
    pub const MAX_PAGE_ADDR: usize = 766;
    pub const PAGE_BYTES: usize = 16;
    pub const PAGE_MASK: u16 = 0x3FFF;

    //=== 命令定义 ===//
    // LSC和ISC到底指代什么东西，我也不知道，Lattice的手册就是依托答辩
    // 通用命令
    pub const LSC_READ_STATUS: u8 = 0x3C;
    pub const LSC_CHECK_BUSY: u8 = 0xF0;
    pub const ISC_NOOP: u8 = 0xFF;
    pub const ISC_ENABLE_X: u8 = 0x74;
    pub const ISC_ENABLE: u8 = 0xC6;
    pub const ISC_DISABLE: u8 = 0x26;
    pub const LSC_WRITE_ADDRESS: u8 = 0xB4;

    // UFM扇区特有命令
    pub const LSC_INIT_ADDR_UFM: u8 = 0x47; // 重置UFM地址
    pub const LSC_READ_TAG: u8 = 0xCA;
    pub const LSC_ERASE_TAG: u8 = 0xCB;
    pub const LSC_PROG_TAG: u8 = 0xC9;

    // CFG扇区特有命令
    pub const IDCODE_PUB: u8 = 0xE0;
    pub const USERCODE: u8 = 0xC0;
    pub const LSC_REFRESH: u8 = 0x79;
    pub const LSC_DEVICE_CTRL: u8 = 0x7D;
    pub const VERIFY_ID: u8 = 0xE2;
    pub const LSC_INIT_ADDRESS: u8 = 0x46;
    pub const LSC_READ_INCR_NV: u8 = 0x73;
    pub const ISC_ERASE: u8 = 0x0E;
    pub const LSC_PROG_INCR_NV: u8 = 0x70;
    pub const ISC_PROGRAM_DONE: u8 = 0x5E;
    pub const ISC_PROGRAM_SECURITY: u8 = 0xCE;
    pub const ISC_PROGRAM_SECPLUS: u8 = 0xCF;
    pub const ISC_PROGRAM_USERCODE: u8 = 0xC2;
    pub const LSC_READ_FEATURE: u8 = 0xE7;
    pub const LSC_PROG_FEATURE: u8 = 0xE4;
    pub const LSC_READ_FEABITS: u8 = 0xFB;
    pub const PROG_TAG: u8 = 0xF8;

    /// 组装命令和操作数
    /// # Notes
    /// `operands` 只有低`3`字节是有效的，低字节先被发送
    #[inline(always)]
    pub const fn asm_cmd_operands(cmd: u8, operands: u32) -> u32 {
        (operands << 8) | cmd as u32
    }

    /// 组装命令和操作数(大端序)，大端序可能有转换开销
    /// # Notes
    /// `operands` 只有低`3`字节是有效的，最高字节必须为`0`，高字节先被发送
    #[inline(always)]
    pub const fn asm_cmd_operands_be(cmd: u8, operands: u32) -> u32 {
        (((cmd as u32) << 24) | operands).swap_bytes()
    }

    /// 命令与操作数的字节总数
    pub const fn cmd_operands_num(cmd: u8) -> usize {
        match cmd {
            Self::ISC_DISABLE | Self::LSC_REFRESH | Self::LSC_DEVICE_CTRL => 3,
            _ => 4,
        }
    }

    pub const fn is_write_cmd(cmd: u8) -> bool {
        matches!(
            cmd,
            Self::LSC_PROG_INCR_NV
                | Self::LSC_WRITE_ADDRESS
                | Self::ISC_PROGRAM_USERCODE
                | Self::LSC_PROG_TAG
                | Self::VERIFY_ID
                | Self::PROG_TAG
        )
    }

    #[inline(always)]
    pub fn reset(&mut self) {
        unsafe {
            self.reg().control.write(0x40.into());
            self.reg().control.write(0x00.into());
        }
    }

    #[inline(always)]
    pub fn nop(&mut self) {
        self.command(|fl| unsafe {
            fl.reg().write_data.write(Self::ISC_NOOP);
        });
    }

    #[inline]
    pub fn command<F: FnOnce(&mut Self) -> ()>(&mut self, f: F) {
        unsafe {
            self.reg().control.write(0x80.into());
            f(self);
            self.reg().control.write(0x00.into());
        }
    }

    /// `buffer`的长度决定了要读取/写入的数据量，如果无数据，请使用空切片
    /// # Notes
    /// 不适合一次性读取多页，因为要额外处理dummy
    pub fn command_frame(&mut self, mut cmd_operands: u32, cmd_op_num: usize, buffer: FlashBuffer) {
        use FlashBuffer::{Read, Write};
        self.command(|fl| {
            // 写入命令与操作数
            for _ in 0..cmd_op_num {
                unsafe { fl.reg().write_data.write(cmd_operands as u8) }
                cmd_operands >>= 8;
            }

            // 读取/写入数据
            match buffer {
                Read(buffer) => {
                    for byte in buffer {
                        *byte = fl.reg().read_data.read();
                    }
                }
                Write(buffer) => {
                    for byte in buffer {
                        unsafe { fl.reg().write_data.write(*byte) }
                    }
                }
            }
        });
    }

    /// 对`command_frame`读取操作的包装
    #[inline]
    pub fn command_frame_read(&mut self, cmd: u8, operands: u32, buffer: &mut [u8]) {
        self.command_frame(
            Self::asm_cmd_operands_be(cmd, operands),
            Self::cmd_operands_num(cmd),
            FlashBuffer::Read(buffer),
        );
    }

    /// 对`command_frame`写入操作的包装
    #[inline]
    pub fn command_frame_write(&mut self, cmd: u8, operands: u32, buffer: &[u8]) {
        self.command_frame(
            Self::asm_cmd_operands_be(cmd, operands),
            Self::cmd_operands_num(cmd),
            FlashBuffer::Write(buffer),
        );
    }

    pub fn flash_id(&mut self) -> u32 {
        let mut id = 0;
        self.command(|fl| {
            flash_write!(fl, Self::IDCODE_PUB, 0, 0, 0);
            id = (fl.reg().read_data.read() as u32) << 24;
            id |= (fl.reg().read_data.read() as u32) << 16;
            id |= (fl.reg().read_data.read() as u32) << 8;
            id |= fl.reg().read_data.read() as u32;
        });
        id
    }

    /// 启用UFM透明传输
    /// # Warning
    /// 启用透明传输会暂时禁用以下功能
    /// 1. 电源控制
    /// 2. 全局置位/复位
    /// 3. 用户SPI接口
    /// 4. 用户主I2C接口
    pub fn enable_transparent_ufm(&mut self) {
        self.command(|fl| flash_write!(fl, Self::ISC_ENABLE_X, 0x08, 0, 0));
        crate::rv_core::delay_us(8); // 至少等5us，保险一点等8us
    }
    /// 关闭UFM透明传输
    pub fn disable_transparent_ufm(&mut self) {
        self.command(|fl| flash_write!(fl, Self::ISC_DISABLE, 0, 0));
        self.nop();
    }

    //<!!! 下面的函数都必须先启用UFM透明传输 !!!>//

    /// 重设页地址为`0`\
    /// **必须先启用UFM透明传输!**
    pub fn reset_ufm_addr(&mut self) {
        self.command(|fl| flash_write!(fl, Self::LSC_INIT_ADDR_UFM, 0, 0, 0));
    }

    /// **必须先启用UFM透明传输!**
    pub fn set_ufm_addr(&mut self, addr: u16) {
        let addr = (addr & Self::PAGE_MASK).to_ne_bytes();
        let buffer = [0x40u8, 0x00, addr[0], addr[1]];
        self.command_frame_write(Self::LSC_WRITE_ADDRESS, 0, &buffer);
    }

    /// 读取一页数据，页地址自会增
    /// **必须先启用UFM透明传输!**
    pub fn read_one_ufm_page(&mut self, buffer: &mut [u8; 16]) {
        self.command_frame_read(Self::LSC_READ_TAG, 0x100001, buffer);
    }

    /// 擦除UFM所有内容 **阻塞约1050毫秒**\
    /// **必须先启用UFM透明传输!**
    pub fn erase_ufm(&mut self) {
        self.command(|fl| flash_write!(fl, Self::LSC_ERASE_TAG, 0, 0, 0));
        crate::rv_core::delay_ms(1050); // MachXO2-4000的最大值是1000ms
    }

    /// 写入一页数据，页地址自会增
    /// **必须先启用UFM透明传输!**
    pub fn write_one_ufm_page(&mut self, buffer: &[u8; 16]) {
        self.command_frame_write(Self::LSC_PROG_TAG, 0x000001, buffer);
        crate::rv_core::delay_us(210); // 至少等200us，保险一点等210us
    }
}

pub type EfbIntSource = Peripheral<regs::EFBInterruptSource, { lb_base(EFB_INT_SOURCE_OFFSET) }>;
impl EfbIntSource {
    /// 指示EFB中断来源于什么
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };
}
