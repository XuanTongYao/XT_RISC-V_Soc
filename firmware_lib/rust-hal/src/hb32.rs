//! 高速32bit对齐总线

use crate::pac::bootstrap::InstanceBootstrap;
use crate::pac::eint_controller::{self, InstanceEintController};
use crate::pac::gpio::InstanceGpio;
use crate::pac::msip::{self, InstanceMsip};
use crate::pac::mtime::InstanceMtime;
use crate::pac::uart::{self, InstanceUart};
use xt_riscv_mcu::rv_core;

// TODO riscv-rust 0.16.2更新之后加入临界区

pub struct Bootstrap {
    inst: InstanceBootstrap,
}

impl Bootstrap {
    const INTO_RAM_MODE: u8 = 0x00;
    const INTO_ROM_MODE: u8 = 0x55;

    pub fn new(inst: InstanceBootstrap) -> Self {
        Self { inst }
    }

    crate::prop_value!(
        /// # Note
        /// 写入无效地址会导致preload寄存器硬件失效
        preload_str_addr,
        preload_str_addr,
        u8,
        set
    );

    #[inline(always)]
    pub fn get_preload_str_u8(&mut self) -> u8 {
        self.inst.regs().preload_str_auto_inc.read()
    }

    #[inline(always)]
    pub fn download_mode(&self) -> bool {
        self.inst.regs().config.read() & 0x01 != 0
    }

    #[inline(always)]
    pub fn ram_mode(&self) -> bool {
        self.inst.regs().config.read() & 0x02 != 0
    }

    /// 将指令区域映射到RAM
    /// # Safety
    /// 使系统硬件复位
    #[inline(always)]
    pub unsafe fn into_ram_mode(&mut self) {
        self.inst.regs().config.write(Self::INTO_RAM_MODE)
    }

    /// 将指令区域映射到ROM
    /// # Safety
    /// 使系统硬件复位
    #[inline(always)]
    pub unsafe fn into_rom_mode(&mut self) {
        self.inst.regs().config.write(Self::INTO_ROM_MODE)
    }
}
pub struct BootstrapPreloadStr {
    pub addr: u8,
    pub len: u8,
}
type PreloadStr = BootstrapPreloadStr;
#[cfg(not(feature = "zh_cn_prompt"))]
impl Bootstrap {
    // "🔓:0x56\n"
    pub const CMD: PreloadStr = PreloadStr { addr: 0, len: 10 };
    // "Len="
    pub const LEN: PreloadStr = PreloadStr { addr: 10, len: 4 };
    // "\n💾:0x78"
    pub const START_DOWNLOAD: PreloadStr = PreloadStr { addr: 14, len: 10 };
    // "\n✅:0x57"
    pub const CONFIRM: PreloadStr = PreloadStr { addr: 24, len: 9 };
    // "\n❌"
    pub const ERR: PreloadStr = PreloadStr { addr: 33, len: 4 };
}
#[cfg(feature = "zh_cn_prompt")]
impl Bootstrap {
    // "下载:0x56\n"
    pub const CMD: PreloadStr = PreloadStr { addr: 0, len: 12 };
    // "Len="
    pub const LEN: PreloadStr = PreloadStr { addr: 12, len: 4 };
    // "\n开始:0x78"
    pub const START_DOWNLOAD: PreloadStr = PreloadStr { addr: 16, len: 12 };
    // "\n完成:0x57"
    pub const CONFIRM: PreloadStr = PreloadStr { addr: 28, len: 12 };
    // "\nERROR"
    pub const ERR: PreloadStr = PreloadStr { addr: 40, len: 6 };
}

pub use eint_controller::interrupt::Interrupt as EintFlags;

pub struct EintController {
    inst: InstanceEintController,
}

use rv_core::ExternalInterrupt;
impl EintController {
    pub fn new(inst: InstanceEintController) -> Self {
        Self { inst }
    }

    crate::prop_value!(unsafe enable, enable, EintFlags, set, modify);
    crate::prop_value!(enable, enable, EintFlags, get);
    crate::prop_value!(pending, pending, EintFlags, get);

    #[inline(always)]
    pub unsafe fn enable_interrupt(&mut self, int: ExternalInterrupt) {
        unsafe { self.enable_interrupt_mask(int.into_mask()) }
    }
    #[inline(always)]
    pub fn disable_interrupt(&mut self, int: ExternalInterrupt) {
        self.disable_interrupt_mask(int.into_mask())
    }

    #[inline(always)]
    pub unsafe fn enable_interrupt_mask(&mut self, mask: u32) {
        unsafe {
            self.modify_enable(|enable| (enable.into_bits() | mask).into());
        }
    }
    #[inline(always)]
    pub fn disable_interrupt_mask(&mut self, mask: u32) {
        unsafe {
            self.modify_enable(|enable| (enable.into_bits() & (!mask)).into());
        }
    }
}

pub struct Mtime {
    inst: InstanceMtime,
}

impl Mtime {
    pub fn new(inst: InstanceMtime) -> Self {
        Self { inst }
    }

    pub const FREQ_MHZ: u32 = 1;
    pub const FREQ_KHZ: u32 = Self::FREQ_MHZ * 1000;
    pub const FREQ_HZ: u32 = Self::FREQ_KHZ * 1000;
    pub const fn us_ticks(us: u64) -> u64 {
        us * Self::FREQ_MHZ as u64
    }
    pub const fn ms_ticks(ms: u64) -> u64 {
        ms * Self::FREQ_KHZ as u64
    }
    pub const fn sec_ticks(second: u64) -> u64 {
        second * Self::FREQ_HZ as u64
    }
    /// 以当前`mtime`为基准，将`mtimecmp`设置为向前的一个时刻\
    /// 其中`ticks`为时间间隔
    #[inline(always)]
    pub fn update_mtimecmp_forward(&mut self, ticks: u64) {
        let mut time = self.mtime();
        time += ticks;
        unsafe { self.set_mtimecmp(time) }
    }
}

#[cfg(target_arch = "riscv32")]
impl Mtime {
    pub fn mtime(&self) -> u64 {
        loop {
            let high = self.inst.regs().mtimeh.read();
            let low = self.inst.regs().mtimel.read();
            if high == self.inst.regs().mtimeh.read() {
                return ((high as u64) << 32) | (low as u64);
            }
        }
    }
    /// # Safety
    /// 设置mtime不当，可能会立即引发定时器中断
    pub unsafe fn set_mtime(&mut self, value: u64) {
        let high = (value >> 32) as u32;
        let low = value as u32;

        self.inst.regs().mtimeh.write(u32::MAX);
        self.inst.regs().mtimel.write(low);
        self.inst.regs().mtimeh.write(high);
    }

    pub fn mtimecmp(&self) -> u64 {
        let high = self.inst.regs().mtimecmph.read();
        let low = self.inst.regs().mtimecmpl.read();
        ((high as u64) << 32) | (low as u64)
    }
    /// # Safety
    /// 设置mtimecmp不当，可能会立即引发定时器中断
    pub unsafe fn set_mtimecmp(&mut self, value: u64) {
        let high = (value >> 32) as u32;
        let low = value as u32;
        self.inst.regs().mtimecmpl.write(u32::MAX);
        self.inst.regs().mtimecmph.write(high);
        self.inst.regs().mtimecmpl.write(low);
    }
}

#[cfg(target_arch = "riscv64")]
impl Mtime {
    crate::prop_value!(mtime, mtime, u64, get, set);
    crate::prop_value!(mtimecmp, mtimecmp, u64, get, set);
}

use uart::status::Status as UartStatus;
pub struct Uart {
    inst: InstanceUart,
}

impl Uart {
    pub const UART_FREQ: u32 = 19200;

    pub fn new(inst: InstanceUart) -> Self {
        Self { inst }
    }

    crate::prop_value!(status, status, UartStatus, get);

    /// 丢弃接收FIFO中的数据
    pub fn discard_rx_fifo(&mut self) {
        while self.status().rx_end() {
            self.rx();
        }
    }

    /// # Note
    /// 读取到最后一次的数据或最新数据
    #[inline]
    pub fn rx(&mut self) -> u8 {
        self.inst.regs().data.read()
    }

    #[inline]
    pub fn rx_block(&mut self) -> u8 {
        while !self.status().rx_end() {}
        self.rx()
    }

    /// # Note
    /// 如果缓冲区已满，则写入将被硬件丢弃
    #[inline]
    pub fn tx(&mut self, byte: u8) {
        self.inst.regs().data.write(byte)
    }

    #[inline]
    pub fn tx_block(&mut self, byte: u8) {
        while !self.status().tx_ready() {}
        self.tx(byte);
    }

    pub fn tx_bytes_block(&mut self, data: &[u8], big_endian: bool) {
        if big_endian {
            for i in data.iter().rev() {
                self.tx_block(*i);
            }
        } else {
            for i in data {
                self.tx_block(*i);
            }
        };
    }
}

impl embedded_io::ErrorType for Uart {
    type Error = !;
}

impl embedded_io::Read for Uart {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize, Self::Error> {
        if buf.len() == 0 {
            return Ok(0);
        }

        while !self.status().rx_end() {}
        let mut count: usize = 0;
        for byte in buf {
            *byte = self.rx();
            count += 1;
            if !self.status().rx_end() {
                break;
            }
        }
        Ok(count)
    }
}

impl embedded_io::ReadReady for Uart {
    fn read_ready(&mut self) -> Result<bool, Self::Error> {
        Ok(self.status().rx_end())
    }
}

impl embedded_io::Write for Uart {
    fn write(&mut self, buf: &[u8]) -> Result<usize, Self::Error> {
        if buf.len() == 0 {
            return Ok(0);
        }

        while !self.status().tx_ready() {}
        let mut count: usize = 0;
        for byte in buf {
            self.tx(*byte);
            count += 1;
            if !self.status().tx_ready() {
                break;
            }
        }
        Ok(count)
    }

    fn flush(&mut self) -> Result<(), Self::Error> {
        while !self.status().tx_empty() {}
        Ok(())
    }
}

impl embedded_io::WriteReady for Uart {
    fn write_ready(&mut self) -> Result<bool, Self::Error> {
        Ok(self.status().tx_ready())
    }
}

pub struct Msip {
    inst: InstanceMsip,
}

impl Msip {
    pub fn new(inst: InstanceMsip) -> Self {
        Self { inst }
    }

    #[inline(always)]
    pub fn is_enabled(&self) -> bool {
        self.inst.regs().msip.read().pending()
    }

    /// # Safety
    /// 会立即引发软件中断
    #[inline(always)]
    pub unsafe fn enable(&mut self) {
        use msip::msip::Msip;
        self.inst.regs().msip.write(Msip::new().with_pending(true));
    }
    #[inline(always)]
    pub fn disable(&mut self) {
        use msip::msip::Msip;
        self.inst.regs().msip.write(Msip::new().with_pending(false));
    }
}

pub struct Gpio {
    inst: InstanceGpio,
}

impl Gpio {
    pub fn new(inst: InstanceGpio) -> Self {
        Self { inst }
    }

    /// 有效GPIO数量
    pub const VALID_COUNT: u32 = 28;

    crate::prop_value!(direction, direction, u32, get, set, modify);
    crate::prop_value!(data, data, u32, get, set, modify);
    crate::prop_value!(af_enable, af_enable, u32, get, set, modify);

    pub fn set_af(&mut self, gpio: u32, af: u32) {
        if gpio >= Self::VALID_COUNT {
            return;
        }

        if gpio >= 16 {
            let offset = (gpio - 16) << 1;
            self.inst
                .regs()
                .afh
                .modify(|reg| reg & !(0b11 << offset) | ((af & 0b11) << offset));
        } else {
            let offset = (gpio) << 1;
            self.inst
                .regs()
                .afl
                .modify(|reg| reg & !(0b11 << offset) | ((af & 0b11) << offset));
        };
    }

    #[inline(always)]
    pub fn af(&mut self, gpio: u32) -> u32 {
        if gpio as u32 >= 16 {
            let offset = (gpio - 16) << 1;
            (self.inst.regs().afh.read() >> offset) & 0b11
        } else {
            let offset = gpio << 1;
            (self.inst.regs().afl.read() >> offset) & 0b11
        }
    }
}
