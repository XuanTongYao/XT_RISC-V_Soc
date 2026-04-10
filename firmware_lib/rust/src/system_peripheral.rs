//! 系统级外设，包含外部中断控制器、mtime等

use volatile_register::RW;

use crate::common::Peripheral;
const DOMAIN_SP_BASE: usize = crate::common::domain_base(2);
const SP_ADDR_LEN: usize = 5;
const SP_ID_LEN: usize = 3;
const SP_OFFSET_LEN: usize = SP_ADDR_LEN - SP_ID_LEN;
const SP_ID_START_BIT: usize = SP_OFFSET_LEN + 2;
enum PeripheralId {
    Bootstrap,
    EintController,
    Mtime,
    Uart,
    SoftwareInt,
}

const fn sp_base(statr_id: PeripheralId) -> usize {
    DOMAIN_SP_BASE + ((statr_id as usize) << SP_ID_START_BIT)
}

pub mod regs {
    use bitfield_struct::bitfield;
    use volatile_register::{RO, RW, WO};

    #[repr(C)]
    pub struct Bootstrap {
        pub debug: RW<u32>,
        pub preload_str_addr: WO<u32>,
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

    #[bitfield(u16)]
    pub struct MSoftwareInt {
        #[bits(15)]
        pub int_code: u16,
        pub pending: bool,
    }
}

pub type Bootstrap = Peripheral<regs::Bootstrap, { sp_base(PeripheralId::Bootstrap) }>;
impl Bootstrap {
    const INTO_NORMAL_MODE: u32 = 0xF0;
    pub const SINGLETON: Self = unsafe { Self::from_ptr(Self::BASE as _) };

    crate::set_value!(
        /// # Safety 
        /// 写入无效地址会导致preload寄存器硬件失效
        unsafe preload_str_addr,preload_str_addr,u32);

    #[inline(always)]
    pub fn get_preload_str_u8(&mut self) -> u8 {
        self.reg().preload_str_auto_inc.read()
    }

    #[inline(always)]
    pub fn is_download_mode(&self) -> bool {
        self.reg().debug.read() != 0
    }

    /// 将指令来源切换至RAM
    #[inline(always)]
    pub fn into_ram_mode(&mut self) {
        unsafe { self.reg().debug.write(Self::INTO_NORMAL_MODE) }
    }
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
    /// `ticks`为时间间隔
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

pub type MSoftwareInt = Peripheral<RW<regs::MSoftwareInt>, { sp_base(PeripheralId::SoftwareInt) }>;
impl MSoftwareInt {
    pub const SINGLETON: MSoftwareInt = unsafe { MSoftwareInt::from_ptr(MSoftwareInt::BASE as _) };

    crate::getset_field!(code,,int_code,u16);
    crate::getset_field!(pending,,pending,bool);

    #[inline(always)]
    pub fn set(&mut self, value: u16) {
        unsafe { self.reg().write(value.into()) }
    }
}
