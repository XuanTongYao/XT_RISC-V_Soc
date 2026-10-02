//! WISHBONE总线外设，主要是FPGA芯片的嵌入式硬核

use core::cmp::max;
use core::marker::PhantomData;
use core::num::NonZeroU16;

use crate::pac::efb_int_source::{self, InstanceEfbIntSource};
use crate::pac::flash::InstanceFlash;
use crate::pac::i2c::{self, InstanceI2c};
use crate::pac::spi::{self, InstanceSpi};
use crate::pac::timer::{self, InstanceTimer};
use embedded_hal::i2c::Operation::{Read, Write};
use embedded_hal::spi::Phase;
use embedded_hal::spi::Polarity;
use xt_riscv_mcu::rv_core;

pub const FREQ_HZ: u32 = rv_core::CORE_FREQ_HZ;

pub struct Master;
pub struct Slave;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct InvalidParameters;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct IncorrectSequence;

macro_rules! get_u16_from_2_u8 {
    ($(#[$doc:meta])* $name:ident, [$reg_h:ident, $reg_l:ident]) => {
        $(#[$doc])*
        #[inline(always)]
        pub fn $name(&self) -> u16 {
            let low = self.inst.regs().$reg_l.read() as u16;
            ((self.inst.regs().$reg_h.read() as u16) << 8) | low
        }
    };
}

pub use i2c::{
    control::Control as I2cControl, i2c_interrupt::I2cInterrupt, status::Status as I2cStatus,
};

/// 实际时钟频率为 `WISHBONE/(div*4)`
pub struct I2c<MS> {
    inst: InstanceI2c,
    /// 延迟的时间必须为(0,6)个I2C时钟周期
    /// 此处保存的是处理器时钟周期
    write_delay_cycles: u16,
    /// 延迟的时间必须为(2,7)个I2C时钟周期
    /// 此处保存的是处理器时钟周期
    read_delay_cycles: u16,
    _marker: PhantomData<MS>,
}

impl<MS> I2c<MS> {
    crate::prop_value!(
        /// # Warning
        /// 设置会使I2C复位
        control,
        control,
        I2cControl,
        get,
        set
    );
    crate::prop_value!(status, status, I2cStatus, get);
    crate::prop_value!(general_call_data, general_call_data, u8, get);
    crate::prop_value!(int_status, int_status, I2cInterrupt, get, set);
    crate::prop_value!(int_en, int_en, I2cInterrupt, get, set, modify);

    #[inline]
    pub fn reset(&mut self) {
        let control = self.control();
        self.set_control(control.with_i2cen(false));
        // NOTE 原始C代码出于未知原因在这里延迟了50us，如果出现问题请加回来
        self.set_control(control.with_i2cen(true));
    }

    pub fn prescale(&self) -> u16 {
        let low = self.inst.regs().br0.read() as u16;
        ((self.inst.regs().br1.read().into_bits() as u16) << 8) | low
    }

    #[inline]
    fn tx(&mut self, byte: u8) {
        self.inst.regs().tx_data.write(byte);
    }
    #[inline]
    fn rx(&mut self) -> u8 {
        self.inst.regs().rx_data.read()
    }
}

impl I2c<Slave> {
    /// 设置预分频为 `div` 范围 `[1,512]`，实际频率为`WISHBONE/(div*4)`
    /// # Warning
    /// 设置预分频会使I2C复位
    pub fn set_prescale(&mut self, div: NonZeroU16) -> Result<(), InvalidParameters> {
        let div = div.get();
        if div > 512 {
            return Err(InvalidParameters);
        }
        self.inst.regs().br0.write(div as u8);
        self.inst.regs().br1.write(((div >> 8) as u8).into());
        self.write_delay_cycles = div * 4;
        self.read_delay_cycles = div * 4 * 4;
        Ok(())
    }
}

impl I2c<Master> {
    pub fn init(inst: InstanceI2c, prescale: NonZeroU16) -> Result<Self, InvalidParameters> {
        let mut i2c = Self {
            inst,
            write_delay_cycles: 0,
            read_delay_cycles: 0,
            _marker: PhantomData,
        };
        i2c.set_control(I2cControl::new());
        i2c.set_prescale(prescale).and(Ok(i2c))
    }
    pub unsafe fn init_unchecked(inst: InstanceI2c, prescale: u16) -> Self {
        let mut i2c = Self {
            inst,
            write_delay_cycles: 0,
            read_delay_cycles: 0,
            _marker: PhantomData,
        };
        i2c.set_control(I2cControl::new());
        unsafe { i2c.set_prescale_unchecked(prescale) }
        i2c
    }

    /// 设置预分频为 `div` 范围 `[1,1023]`，实际频率为`WISHBONE/(div*4)`
    /// # Warning
    /// 设置预分频会使I2C复位
    #[inline]
    pub fn set_prescale(&mut self, div: NonZeroU16) -> Result<(), InvalidParameters> {
        let div = div.get();
        if div >= 1024 {
            return Err(InvalidParameters);
        }
        unsafe { self.set_prescale_unchecked(div) }
        Ok(())
    }
    unsafe fn set_prescale_unchecked(&mut self, div: u16) {
        self.inst.regs().br0.write(div as u8);
        self.inst.regs().br1.write(((div >> 8) as u8).into());
        self.write_delay_cycles = div * 4;
        self.read_delay_cycles = div * 4 * 4;
    }

    /// (重)启动传输并进入**写入模式**，`addr`为左对齐的7bit地址(最低位为0)
    fn start_write(&mut self, addr: u8) {
        self.tx(addr); // 最低位为0表示写操作
        self.inst.regs().command.write(0x94.into());
        while !self.status().trrdy() {}
        rv_core::delay(self.write_delay_cycles as u32); // 等(0,6)个I2C时钟周期
    }

    /// 必须处于**写入模式**中才能调用此函数，必须在此数据帧开始之前设置
    ///
    /// 返回**上一帧**ACK的bit值，1为NACK
    fn write_block(&mut self, byte: u8) -> bool {
        self.tx(byte);
        self.inst.regs().command.write(0x14.into());
        while !self.status().trrdy() {}
        rv_core::delay(self.write_delay_cycles as u32); // 等(0,6)个I2C时钟周期
        self.status().rarc()
    }

    /// 结束**写入模式**传输
    #[inline(always)]
    fn finish_write(&mut self) {
        self.inst.regs().command.write(0x44.into())
    }

    /// (重)启动传输并进入**读取模式**，`addr`为左对齐的7bit地址(最低位为0)
    ///
    /// 返回ACK的bit值，1为NACK
    fn start_read(&mut self, addr: u8) -> bool {
        self.tx(addr | 0x01); // 最低位为1表示读操作
        self.inst.regs().command.write(0x94.into());
        while !self.status().srw() {}
        self.inst.regs().command.write(0x24.into());
        self.status().rarc()
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`finish_read_block`来获取
    fn read_block(&mut self) -> u8 {
        while !self.status().trrdy() {}
        self.rx()
    }

    /// 结束**读取模式**传输\
    /// 返回最后一个读取到的字节
    fn finish_read_block(&mut self, stop: bool) -> u8 {
        use i2c::command::Command;
        rv_core::delay(self.read_delay_cycles as u32); // 等(2,7)个I2C时钟周期
        let cmd = Command::new()
            .with_ack(true)
            .with_read(true)
            .with_stop(stop);
        self.inst.regs().command.write(cmd);
        let last_byte = self.read_block();
        if stop {
            self.inst.regs().command.write(Command::new());
        }
        last_byte
    }
}

#[derive(Debug)]
pub struct I2cError(embedded_hal::i2c::ErrorKind);

impl embedded_hal::i2c::Error for I2cError {
    fn kind(&self) -> embedded_hal::i2c::ErrorKind {
        self.0
    }
}

impl embedded_hal::i2c::ErrorType for I2c<Master> {
    type Error = I2cError;
}

impl embedded_hal::i2c::I2c for I2c<Master> {
    /// 传入的地址必须是右对齐的7bit地址，遵循HAL的约定
    fn transaction(
        &mut self,
        address: u8,
        operations: &mut [embedded_hal::i2c::Operation<'_>],
    ) -> Result<(), Self::Error> {
        use embedded_hal::i2c::{ErrorKind::*, NoAcknowledgeSource};

        let addr = address << 1;

        #[derive(PartialEq, Eq)]
        enum OpType {
            Null,
            Read,
            Write,
        }
        let mut last_op = OpType::Null;

        // 等待空闲
        self.set_control(I2cControl::new().with_i2cen(true));
        while self.status().busy() {}

        let mut op_iter = operations.iter_mut().peekable();

        let mut err = Ok(());
        'op_loop: while let Some(op) = op_iter.next() {
            if let Read(buf) = op {
                if last_op != OpType::Read {
                    last_op = OpType::Read;
                    if self.start_read(addr) {
                        err = Err(I2cError(NoAcknowledge(NoAcknowledgeSource::Address)));
                        break 'op_loop;
                    }
                }

                let mut iter = buf.iter_mut().peekable();

                let mut last_byte = None;
                while let Some(byte) = iter.next() {
                    if let None = iter.peek() {
                        last_byte = Some(byte);
                        break;
                    }
                    *byte = self.read_block();
                }

                let rdata = match op_iter.peek() {
                    None => self.finish_read_block(true),
                    Some(Read(_)) => self.read_block(),
                    _ => self.finish_read_block(false),
                };
                if let Some(last_byte) = last_byte {
                    *last_byte = rdata;
                }
            } else if let Write(buf) = op {
                let mut iter = buf.iter();
                if last_op != OpType::Write {
                    last_op = OpType::Write;
                    self.start_write(addr);
                    if let Some(first_byte) = iter.next() {
                        if self.write_block(*first_byte) {
                            err = Err(I2cError(NoAcknowledge(NoAcknowledgeSource::Address)));
                            break 'op_loop;
                        }
                    }
                }

                for byte in iter {
                    if self.write_block(*byte) {
                        err = Err(I2cError(NoAcknowledge(NoAcknowledgeSource::Data)));
                        break 'op_loop;
                    }
                }

                if let None = op_iter.peek() {
                    self.finish_write();
                }
            }
        }
        if err.is_err() {
            self.inst.regs().command.write(0x44.into());
            while self.status().busy() {}
        }
        self.set_control(I2cControl::new().with_i2cen(false));
        err
    }
}

pub use spi::control0::Control0 as SpiControl0;
pub use spi::control1::Control1 as SpiControl1;
pub use spi::control2::Control2 as SpiControl2;
pub use spi::spi_interrupt::SpiInterrupt;
pub use spi::status::Status as SpiStatus;

pub struct Spi<MS> {
    inst: InstanceSpi,
    pub dummy_byte: u8,
    in_progress: bool,
    _marker: PhantomData<MS>,
}

pub use embedded_hal::spi::Mode as SpiMode;
impl<MS> Spi<MS> {
    crate::prop_value!(
        /// # Warning
        /// 写入会使SPI复位
        control0,
        control0,
        SpiControl0,
        get,
        set
    );
    crate::prop_value!(control1, control1, SpiControl1, get);
    crate::prop_value!(control2, control2, SpiControl2, get);

    crate::prop_value!(
        /// # Warning
        /// 写入会使SPI复位
        cs,
        cs,
        u8,
        get,
        set
    );

    crate::prop_value!(status, status, SpiStatus, get);
    crate::prop_value!(int_status, int_status, SpiInterrupt, get, set);
    crate::prop_value!(int_en, int_en, SpiInterrupt, get, set, modify);

    /// 获取预分频`div`，实际频率为`WISHBONE/(div+1)`
    pub fn prescale(&self) -> u8 {
        self.inst.regs().clock_prescale.read()
    }

    /// 设置预分频为 `div` 范围 `[4,63]`，实际频率为`WISHBONE/(div+1)`
    /// # Warning
    /// 重设预分频会使SPI复位
    pub fn set_prescale(&mut self, div: u8) -> Result<(), InvalidParameters> {
        // 实际允许[1,63]的分频，但是要使用mcsh，div必须>=4
        if div < 4 || div >= 64 {
            return Err(InvalidParameters);
        }
        self.inst.regs().clock_prescale.write(div);
        Ok(())
    }

    /// # Warning
    /// 更改模式会使SPI复位
    pub fn set_mode(&mut self, mode: SpiMode, lsb_first: bool) {
        self.inst.regs().control2.modify(|con| {
            con.with_cpol(mode.polarity == Polarity::IdleHigh)
                .with_cpha(mode.phase == Phase::CaptureOnSecondTransition)
                .with_lsbf(lsb_first)
        });
    }

    #[inline]
    fn tx(&mut self, byte: u8) {
        self.inst.regs().tx_data.write(byte);
    }
    #[inline]
    fn rx(&mut self) -> u8 {
        self.inst.regs().rx_data.read()
    }
}

impl Spi<Slave> {
    pub fn init(inst: InstanceSpi, dummy_byte: u8, mode: SpiMode, lsb_first: bool) -> Self {
        let spi: Self = Spi {
            inst,
            dummy_byte,
            in_progress: false,
            _marker: PhantomData,
        };

        let con1 = SpiControl1::new().with_spe(true);
        let con2 = SpiControl2::new()
            .with_cpol(mode.polarity == Polarity::IdleHigh)
            .with_cpha(mode.phase == Phase::CaptureOnSecondTransition)
            .with_lsbf(lsb_first);

        spi.inst.regs().control0.write(0.into());
        spi.inst.regs().control1.write(con1);
        spi.inst.regs().control2.write(con2);
        spi
    }

    pub fn into_master(self) -> Spi<Master> {
        let spi: Spi<Master> = Spi {
            inst: self.inst,
            dummy_byte: self.dummy_byte,
            in_progress: false,
            _marker: PhantomData,
        };

        spi.inst
            .regs()
            .control2
            .modify(|con| con.with_mstr(true).with_mcsh(false));
        spi
    }

    pub fn restart_rw_block(&mut self, byte0: u8, byte1: u8) -> u8 {
        while self.status().tip() {}
        self.rx();
        self.rx(); // 丢弃2字节
        self.tx(byte0);
        // IDLE
        while !self.status().tip() {}
        self.tx(byte1);
        while !self.status().rrdy() {}
        self.rx()
    }

    /// 调用`slave_restart_rw_block`后才能使用此函数执行读写操作
    pub fn rw_byte_block(&mut self, next_byte: u8) -> u8 {
        while !self.status().trdy() {}
        self.tx(next_byte);
        while !self.status().rrdy() {}
        self.rx()
    }
}

impl Spi<Master> {
    pub fn init(inst: InstanceSpi, dummy_byte: u8, mode: SpiMode, lsb_first: bool) -> Self {
        let spi: Self = Spi {
            inst,
            dummy_byte,
            in_progress: false,
            _marker: PhantomData,
        };

        let con1 = SpiControl1::new().with_spe(true);
        let con2 = SpiControl2::new()
            .with_mstr(true)
            .with_cpol(mode.polarity == Polarity::IdleHigh)
            .with_cpha(mode.phase == Phase::CaptureOnSecondTransition)
            .with_lsbf(lsb_first);

        spi.inst.regs().control0.write(0.into());
        spi.inst.regs().control1.write(con1);
        spi.inst.regs().control2.write(con2);
        spi
    }

    pub fn into_slave(self) -> Spi<Slave> {
        let spi: Spi<Slave> = Spi {
            inst: self.inst,
            dummy_byte: self.dummy_byte,
            in_progress: false,
            _marker: PhantomData,
        };

        spi.inst
            .regs()
            .control2
            .modify(|con| con.with_mstr(false).with_mcsh(false));
        spi
    }

    /// 未启动传输/使用`start_rw_block()`结束传输后此函数才会成功
    #[inline]
    pub fn try_start_rw_block(&mut self, byte: u8) -> Result<u8, IncorrectSequence> {
        if !self.in_progress {
            self.inst.regs().control2.modify(|con| con.with_mcsh(true));
            while !self.status().trdy() {}
            self.in_progress = true;
            Ok(self.rw_byte_block(byte))
        } else {
            Err(IncorrectSequence)
        }
    }

    /// 使用`start_rw_block()`启动传输后此函数才会成功
    #[inline]
    pub fn try_rw_byte_block(&mut self, byte: u8) -> Result<u8, IncorrectSequence> {
        if self.in_progress {
            Ok(self.rw_byte_block(byte))
        } else {
            Err(IncorrectSequence)
        }
    }

    /// 使用`start_rw_block()`启动传输后此函数才会成功
    #[inline]
    pub fn try_finish_rw_block(&mut self) -> Result<(), IncorrectSequence> {
        if self.in_progress {
            self.finish_rw_block();
            Ok(())
        } else {
            Err(IncorrectSequence)
        }
    }

    fn start_rw_block(&mut self, byte: u8) -> u8 {
        self.inst.regs().control2.modify(|con| con.with_mcsh(true));
        while !self.status().trdy() {}
        self.in_progress = true;
        self.rw_byte_block(byte)
    }

    /// 调用`start_rw_block`后才能使用此函数执行读写操作
    fn rw_byte_block(&mut self, byte: u8) -> u8 {
        self.tx(byte);
        while !self.status().rrdy() {}
        self.rx()
    }

    /// 调用`start_rw_block`后才能使用此函数
    fn finish_rw_block(&mut self) {
        self.inst.regs().control2.modify(|con| con.with_mcsh(false));
        while self.status().tip() {}
        self.in_progress = false;
    }
}

impl embedded_hal::spi::ErrorType for Spi<Master> {
    type Error = !;
}

impl embedded_hal::spi::SpiBus for Spi<Master> {
    fn read(&mut self, words: &mut [u8]) -> Result<(), Self::Error> {
        if words.is_empty() {
            return Ok(());
        }

        words[0] = self.start_rw_block(self.dummy_byte);
        for i in 1..words.len() {
            words[i] = self.rw_byte_block(self.dummy_byte);
        }
        self.finish_rw_block();
        Ok(())
    }

    fn write(&mut self, words: &[u8]) -> Result<(), Self::Error> {
        if words.is_empty() {
            return Ok(());
        }

        self.start_rw_block(words[0]);
        for i in 1..words.len() {
            self.rw_byte_block(words[i]);
        }
        self.finish_rw_block();
        Ok(())
    }

    fn transfer(&mut self, read: &mut [u8], write: &[u8]) -> Result<(), Self::Error> {
        let count = max(read.len(), write.len());
        if count == 0 {
            return Ok(());
        }

        let first_write = write.first().copied().unwrap_or(self.dummy_byte);
        let first_read = self.start_rw_block(first_write);
        if !read.is_empty() {
            read[0] = first_read;
        }

        for i in 1..count {
            let wbyte = write.get(i).copied().unwrap_or(self.dummy_byte);
            let rbyte = self.rw_byte_block(wbyte);
            if i < read.len() {
                read[i] = rbyte;
            }
        }
        self.finish_rw_block();
        Ok(())
    }

    fn transfer_in_place(&mut self, words: &mut [u8]) -> Result<(), Self::Error> {
        if words.is_empty() {
            return Ok(());
        }

        let rbyte = self.start_rw_block(words[0]);
        words[0] = rbyte;
        for i in 1..words.len() {
            let rbyte = self.rw_byte_block(words[i]);
            words[i] = rbyte;
        }
        self.finish_rw_block();
        Ok(())
    }

    fn flush(&mut self) -> Result<(), Self::Error> {
        while self.status().tip() {}
        Ok(())
    }
}

pub use timer::control0::{Control0 as TimerControl0, TimerClkSel, TimerDivider};
pub use timer::control1::{Control1 as TimerControl1, TimerCounterMode, TimerOutputMode};
pub use timer::control2::Control2 as TimerControl2;
pub use timer::status::Status as TimerStatus;
pub use timer::timer_interrupt::TimerInterrupt;
pub struct Timer {
    inst: InstanceTimer,
}

pub enum TimerMode {
    StaticLow(TimerCounterMode),
    ToggleOnTopWatchDog,
    ToggleOnTopClearTimerOnTop,
    SetClearFastPWM,
    ClearSetFastPWM,
    SetClearPhaseAndFrequencyCorrectPWM,
    ClearSetPhaseAndFrequencyCorrectPWM,
}

impl Timer {
    pub fn init(inst: InstanceTimer, control0: TimerControl0) -> Self {
        let mut timer = Self { inst };
        timer.set_control0(control0);

        timer
    }
    pub fn new(inst: InstanceTimer) -> Self {
        Self { inst }
    }

    crate::prop_value!(control0, control0, TimerControl0, get, set, modify);
    crate::prop_value!(control2, control2, TimerControl2, get, set);

    pub fn set_mode(&mut self, mode: TimerMode) {
        use TimerCounterMode::*;
        use TimerMode::*;
        use TimerOutputMode::*;
        let (output, counter) = match mode {
            TimerMode::StaticLow(counter) => (TimerOutputMode::StaticLow, counter),
            ToggleOnTopWatchDog => (ToggleOnTop, Watchdog),
            ToggleOnTopClearTimerOnTop => (ToggleOnTop, ClearTimerOnTop),
            SetClearFastPWM => (SetClear, FastPWM),
            ClearSetFastPWM => (ClearSet, FastPWM),
            SetClearPhaseAndFrequencyCorrectPWM => (SetClear, PhaseAndFrequencyCorrectPWM),
            ClearSetPhaseAndFrequencyCorrectPWM => (ClearSet, PhaseAndFrequencyCorrectPWM),
        };

        self.inst
            .regs()
            .control1
            .modify(|con| con.with_tcm(counter).with_ocm(output));
    }
    crate::getset_field!(enable_overflow_flag, control1, sovfen, bool);
    crate::getset_field!(top_autoload, control1, tsel, bool);
    crate::getset_field!(enable_input_capture, control1, icen, bool);

    #[inline]
    pub fn set_top(&mut self, value: u16) {
        self.inst.regs().top_setl.write(value as u8);
        self.inst.regs().top_seth.write((value >> 8) as u8);
    }
    #[inline]
    pub fn set_compare(&mut self, value: u16) {
        self.inst.regs().compare_setl.write(value as u8);
        self.inst.regs().compare_seth.write((value >> 8) as u8);
    }

    get_u16_from_2_u8!(counter, [counterh, counterl]);
    get_u16_from_2_u8!(top, [toph, topl]);
    get_u16_from_2_u8!(compare, [compareh, comparel]);
    get_u16_from_2_u8!(capture, [captureh, capturel]);

    crate::prop_value!(status, status, TimerStatus, get);
    crate::prop_value!(int_status, int_status, TimerInterrupt, get, set);
    crate::prop_value!(int_en, int_en, TimerInterrupt, get, set, modify);
}

impl embedded_hal::pwm::ErrorType for Timer {
    type Error = !;
}

impl embedded_hal::pwm::SetDutyCycle for Timer {
    fn max_duty_cycle(&self) -> u16 {
        return u16::MAX;
    }

    fn set_duty_cycle(&mut self, duty: u16) -> Result<(), Self::Error> {
        self.set_top_autoload(false);
        self.set_mode(TimerMode::ClearSetFastPWM);
        self.set_control0(TimerControl0::new().with_prescale(TimerDivider::Div1));
        self.set_compare(duty);
        Ok(())
    }
}

pub struct Flash {
    inst: InstanceFlash,
}
pub enum FlashBuffer<'a> {
    Read(&'a mut [u8]),
    Write(&'a [u8]),
}

macro_rules! flash_write {
    ($flash:ident, $($byte:expr),+) => {
        {
            $( $flash.inst.regs().write_data.write($byte); )*
        }
    };
}
impl Flash {
    pub fn new(inst: InstanceFlash) -> Self {
        Self { inst }
    }

    pub const TOTAL_PAGE: usize = 767;
    pub const MAX_PAGE_ADDR: usize = 766;
    pub const PAGE_BYTES: usize = 16;
    pub const PAGE_MASK: u16 = 0x3FFF;

    //=== 命令定义 ===//
    // 通用命令
    pub const LSC_READ_STATUS: u8 = 0x3C;
    pub const LSC_CHECK_BUSY: u8 = 0xF0;
    pub const ISC_NOOP: u8 = 0xFF; // 唯一用处：在ISC_DISABLE命令后必须接此命令
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
        self.inst.regs().control.write(0x40.into());
    }

    #[inline]
    pub fn command<F: FnOnce(&mut Self) -> ()>(&mut self, f: F) {
        self.inst.regs().control.write(0x80.into());
        f(self);
        self.inst.regs().control.write(0x00.into());
    }

    /// `buffer`的长度决定了要读取/写入的数据量，如果无数据，请使用空切片
    /// # Notes
    /// 不适合一次性读取多页，因为要额外处理dummy
    pub fn command_frame_raw(
        &mut self,
        mut cmd_operands: u32,
        cmd_op_num: usize,
        buffer: FlashBuffer,
    ) {
        use FlashBuffer::{Read, Write};
        self.command(|fl| {
            // 写入命令与操作数
            for _ in 0..cmd_op_num {
                fl.inst.regs().write_data.write(cmd_operands as u8);
                cmd_operands >>= 8;
            }

            // 读取/写入数据
            match buffer {
                Read(buffer) => {
                    for byte in buffer {
                        *byte = fl.inst.regs().read_data.read();
                    }
                }
                Write(buffer) => {
                    for byte in buffer {
                        fl.inst.regs().write_data.write(*byte);
                    }
                }
            }
        });
    }

    /// 对`command_frame_raw`的包装 自动组装命令操作数并计算命令操作数数量
    #[inline]
    pub fn command_frame(&mut self, cmd: u8, operands: u32, buffer: FlashBuffer) {
        self.command_frame_raw(
            Self::asm_cmd_operands_be(cmd, operands),
            Self::cmd_operands_num(cmd),
            buffer,
        );
    }

    pub fn flash_id(&mut self) -> u32 {
        let mut id = 0;
        self.command(|fl| {
            flash_write!(fl, Self::IDCODE_PUB, 0, 0, 0);
            id = (fl.inst.regs().read_data.read() as u32) << 24;
            id |= (fl.inst.regs().read_data.read() as u32) << 16;
            id |= (fl.inst.regs().read_data.read() as u32) << 8;
            id |= fl.inst.regs().read_data.read() as u32;
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
        rv_core::delay_us(8); // 至少等5us，保险一点等8us
    }
    /// 关闭UFM透明传输
    pub fn disable_transparent_ufm(&mut self) {
        self.command(|fl| flash_write!(fl, Self::ISC_DISABLE, 0, 0));
        self.command(|fl| flash_write!(fl, Self::ISC_NOOP));
    }

    //<!!! 下面的函数都必须先启用UFM透明传输 !!!>//

    /// 重设页地址为`0`\
    /// **必须先启用UFM透明传输!**
    pub fn reset_ufm_addr(&mut self) {
        self.command(|fl| flash_write!(fl, Self::LSC_INIT_ADDR_UFM, 0, 0, 0));
    }

    /// **必须先启用UFM透明传输!**
    pub fn set_ufm_addr(&mut self, addr: u16) {
        let addr = (addr & Self::PAGE_MASK).to_be_bytes();
        let buffer = [0x40u8, 0x00, addr[0], addr[1]];
        self.command_frame(Self::LSC_WRITE_ADDRESS, 0, FlashBuffer::Write(&buffer));
    }

    /// 读取一页数据，页地址自会增
    /// **必须先启用UFM透明传输!**
    pub fn read_one_ufm_page(&mut self, buffer: &mut [u8; 16]) {
        self.command_frame(Self::LSC_READ_TAG, 0x10_00_01, FlashBuffer::Read(buffer));
    }

    /// 擦除UFM所有内容 **阻塞约1050毫秒**\
    /// **必须先启用UFM透明传输!**
    pub fn erase_ufm(&mut self) {
        self.command(|fl| flash_write!(fl, Self::LSC_ERASE_TAG, 0, 0, 0));
        rv_core::delay_ms(1050); // MachXO2-4000的最大值是1000ms
    }

    /// 写入一页数据，页地址自会增
    /// **必须先启用UFM透明传输!**
    pub fn write_one_ufm_page(&mut self, buffer: &[u8; 16]) {
        self.command_frame(Self::LSC_PROG_TAG, 0x00_00_01, FlashBuffer::Write(buffer));
        rv_core::delay_us(210); // 至少等200us，保险一点等210us
    }

    /// `read_one_ufm_page`的裸指针版本
    pub unsafe fn read_one_ufm_page_ptr(&mut self, mut ptr: *mut u8) -> *mut u8 {
        self.command(|fl| {
            flash_write!(fl, Self::LSC_READ_TAG, 0x10, 0x00, 0x01);
            for _ in 0..Self::PAGE_BYTES {
                unsafe {
                    ptr.write_volatile(fl.inst.regs().read_data.read());
                    ptr = ptr.add(1);
                }
            }
        });
        ptr
    }

    /// `write_one_ufm_page`的裸指针版本
    pub unsafe fn write_one_ufm_page_ptr(&mut self, mut ptr: *const u8) -> *const u8 {
        self.command(|fl| {
            flash_write!(fl, Self::LSC_PROG_TAG, 0x00, 0x00, 0x01);
            for _ in 0..Self::PAGE_BYTES {
                unsafe {
                    fl.inst.regs().write_data.write(ptr.read_volatile());
                    ptr = ptr.add(1);
                }
            }
        });
        rv_core::delay_us(210); // 至少等200us，保险一点等210us
        ptr
    }
}

use efb_int_source::source::Source as EfbIntFlags;
/// 指示EFB中断来源于什么
pub struct EfbIntSource {
    inst: InstanceEfbIntSource,
}
impl EfbIntSource {
    pub fn new(inst: InstanceEfbIntSource) -> Self {
        Self { inst }
    }

    crate::prop_value!(source, source, EfbIntFlags, get);
}
