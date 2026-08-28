//! 高速32bit对齐总线

use volatile_register::RW;

use crate::common::Peripheral;
const DOMAIN_HB32_BASE: usize = crate::common::domain_base(2);
const HB32_ADDR_LEN: usize = 6;
const HB32_ID_LEN: usize = 3;
const HB32_OFFSET_LEN: usize = HB32_ADDR_LEN - HB32_ID_LEN;
const HB32_ID_START_BIT: usize = HB32_OFFSET_LEN + 2;
enum PeripheralId {
    Bootstrap,
    EintController,
    Mtime,
    Uart,
    Msip,
    Gpio,
}

const fn sp_base(statr_id: PeripheralId) -> usize {
    DOMAIN_HB32_BASE + ((statr_id as usize) << HB32_ID_START_BIT)
}

pub mod regs {
    use bitfield_struct::bitfield;
    use volatile_register::{RO, RW, WO};

    #[repr(C)]
    pub struct Bootstrap {
        pub config: RW<u8>,
        __: [u8; 3],
        pub preload_str_addr: WO<u8>,
        ___: [u8; 3],
        pub preload_str_auto_inc: RO<u8>,
    }

    #[repr(C)]
    pub struct EintController {
        pub enable: RW<u32>,
        pub pending: RO<u32>,
    }

    #[cfg(target_arch = "riscv32")]
    #[repr(C)]
    pub struct Mtime {
        pub mtimel: RW<u32>,
        pub mtimeh: RW<u32>,
        pub mtimecmpl: RW<u32>,
        pub mtimecmph: RW<u32>,
    }

    #[cfg(target_arch = "riscv64")]
    #[repr(C)]
    pub struct Mtime {
        pub mtime: RW<u64>,
        pub mtimecmp: RW<u64>,
    }

    #[repr(C)]
    pub struct Uart {
        pub data: RW<u8>,
        pub status: RO<UartStatus>,
    }

    #[bitfield(u32)]
    pub struct UartStatus {
        pub tx_ready: bool,
        pub rx_end: bool,
        pub tx_empty: bool, // 发送缓冲区空
        pub rx_full: bool,  // 接收缓冲区已满
        #[bits(28)]
        __: u32,
    }

    #[repr(C)]
    pub struct Gpio {
        pub direction: RW<u32>,
        pub data: RW<u32>,
        pub af_enable: RW<u32>,
        pub afl: RW<u32>,
        pub afh: RW<u32>,
    }
}

pub type Bootstrap = Peripheral<regs::Bootstrap, { sp_base(PeripheralId::Bootstrap) }>;
impl Bootstrap {
    const INTO_RAM_MODE: u8 = 0x00;
    const INTO_ROM_MODE: u8 = 0x55;
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    crate::set_value!(
        /// # Safety 
        /// 写入无效地址会导致preload寄存器硬件失效
        unsafe preload_str_addr,preload_str_addr,u8);

    #[inline(always)]
    pub fn get_preload_str_u8(&mut self) -> u8 {
        self.reg().preload_str_auto_inc.read()
    }

    #[inline(always)]
    pub fn is_download_mode(&self) -> bool {
        self.reg().config.read() != 0
    }

    /// 将指令区域映射到RAM
    /// # Safety
    /// 使系统硬件复位
    #[inline(always)]
    pub unsafe fn into_ram_mode(&mut self) {
        unsafe { self.reg().config.write(Self::INTO_RAM_MODE) }
    }

    /// 将指令区域映射到ROM
    /// # Safety
    /// 使系统硬件复位
    #[inline(always)]
    pub unsafe fn into_rom_mode(&mut self) {
        unsafe { self.reg().config.write(Self::INTO_ROM_MODE) }
    }
}
pub struct BootstrapPreloadStr {
    pub addr: u8,
    pub len: u8,
}
type PreloadStr = BootstrapPreloadStr;
#[cfg(feature = "emoji_prompt")]
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

pub type EintController =
    Peripheral<regs::EintController, { sp_base(PeripheralId::EintController) }>;
use crate::rv_core::ExternalInterrupt;
impl EintController {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    crate::set_value!(unsafe enable, enable, u32);
    crate::get_value!(enable, enable, u32);
    crate::get_value!(pending, pending, u32);

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
        unsafe { self.reg().enable.modify(|enable| enable | mask) }
    }
    #[inline(always)]
    pub fn disable_interrupt_mask(&mut self, mask: u32) {
        unsafe { self.reg().enable.modify(|enable| enable & (!mask)) }
    }
}

pub type Mtime = Peripheral<regs::Mtime, { sp_base(PeripheralId::Mtime) }>;
impl Mtime {
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };
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
            let high = self.reg().mtimeh.read();
            let low = self.reg().mtimel.read();
            if high == self.reg().mtimeh.read() {
                return ((high as u64) << 32) | (low as u64);
            }
        }
    }
    /// # Safety
    /// 设置mtime不当，可能会立即引发定时器中断
    pub unsafe fn set_mtime(&mut self, value: u64) {
        let high = (value >> 32) as u32;
        let low = value as u32;
        unsafe {
            self.reg().mtimeh.write(u32::MAX);
            self.reg().mtimel.write(low);
            self.reg().mtimeh.write(high);
        }
    }

    pub fn mtimecmp(&self) -> u64 {
        let high = self.reg().mtimecmph.read();
        let low = self.reg().mtimecmpl.read();
        ((high as u64) << 32) | (low as u64)
    }
    /// # Safety
    /// 设置mtimecmp不当，可能会立即引发定时器中断
    pub unsafe fn set_mtimecmp(&mut self, value: u64) {
        let high = (value >> 32) as u32;
        let low = value as u32;
        unsafe {
            self.reg().mtimecmpl.write(u32::MAX);
            self.reg().mtimecmph.write(high);
            self.reg().mtimecmpl.write(low);
        }
    }
}

#[cfg(target_arch = "riscv64")]
impl Mtime {
    crate::getset_value!(mtime, mtime, u64);
    crate::getset_value!(mtimecmp, mtimecmp, u64);
}

pub type Uart = Peripheral<regs::Uart, { sp_base(PeripheralId::Uart) }>;
impl Uart {
    pub const UART_FREQ: u32 = 19200;
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    #[inline]
    pub fn has_data(&self) -> bool {
        self.reg().status.read().rx_end()
    }

    /// 丢弃接收FIFO中的数据
    #[inline]
    pub fn discard_rx_fifo(&mut self) {
        while self.reg().status.read().rx_end() {
            unsafe { self.rx_forced() };
        }
    }

    /// # Safety
    /// 强制读取，可能会读取到**无效数据**
    #[inline]
    pub unsafe fn rx_forced(&mut self) -> u8 {
        self.reg().data.read()
    }

    #[inline]
    pub fn rx_block(&mut self) -> u8 {
        while !self.reg().status.read().rx_end() {}
        self.reg().data.read()
    }

    #[inline]
    pub fn rx_bytes_into_block(&mut self, buffer: &mut [u8]) {
        for byte in buffer {
            *byte = self.rx_block();
        }
    }

    #[inline]
    pub fn tx_block(&mut self, byte: u8) {
        while !self.reg().status.read().tx_ready() {}
        unsafe { self.reg().data.write(byte) }
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

pub type Msip = Peripheral<RW<u32>, { sp_base(PeripheralId::Msip) }>;
impl Msip {
    pub const SINGLETON: Msip = unsafe { Msip::from_ptr(Msip::BASE as _) };
    #[inline(always)]
    pub fn is_enabled() -> bool {
        Self::SINGLETON.reg().read() != 0
    }

    /// # Safety
    /// 会立即引发软件中断
    #[inline(always)]
    pub unsafe fn enable(&mut self) {
        unsafe { self.reg().write(0x01) }
    }
    #[inline(always)]
    pub fn disable(&mut self) {
        unsafe { self.reg().write(0x00) }
    }
}

pub type Gpio = Peripheral<regs::Gpio, { sp_base(PeripheralId::Gpio) }>;
impl Gpio {
    pub const SINGLETON: Gpio = unsafe { Gpio::from_ptr(Gpio::BASE as _) };

    /// 有效GPIO数量
    pub const VALID_COUNT: u32 = 28;

    crate::getsetm_value!(direction, direction, u32);
    crate::getsetm_value!(data, data, u32);
    crate::getsetm_value!(af_enable, af_enable, u32);

    pub fn set_af(&mut self, gpio: u32, af: u32) {
        if gpio >= Self::VALID_COUNT {
            return;
        }

        if gpio >= 16 {
            let offset = (gpio - 16) << 1;
            unsafe {
                self.reg()
                    .afh
                    .modify(|af_reg| (af_reg & (0xFFFF_FFFC << offset)) | (af << offset));
            }
        } else {
            let offset = (gpio) << 1;
            unsafe {
                self.reg()
                    .afl
                    .modify(|af_reg| (af_reg & (0xFFFF_FFFC << offset)) | (af << offset));
            }
        };
    }

    #[inline(always)]
    pub fn af(&mut self, gpio: u32) -> u32 {
        if gpio as u32 >= 16 {
            let offset = (gpio - 16) << 1;
            (self.reg().afh.read() >> offset) & 0b11
        } else {
            let offset = gpio << 1;
            (self.reg().afl.read() >> offset) & 0b11
        }
    }
}
