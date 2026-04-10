pub const CORE_FREQ_MHZ: u32 = 12;
pub const CORE_FREQ_KHZ: u32 = CORE_FREQ_MHZ * 1000;
pub const CORE_FREQ_HZ: u32 = CORE_FREQ_KHZ * 1000;

// 适配 riscv::asm::delay 递减计数粗略延时 内部循环次数 `real_cyc = 1 + cycles / 2`
// 流水线实际循环: `addi->bnez->if_id->id_ex->addi` 循环N次消耗 `(N-1)*4+2` 个周期
// cycles=8 -> real_cyc=5 -> 18周期
// cycles=8/2 -> real_cyc=3 -> 10周期
// 所以要在原基础上除以2，才能正确延时
/// 粗略延时`riscv::asm::delay`的内核适配版本\
/// **当`cycles`为奇数时，可能会少一个周期**
#[inline(always)]
pub fn delay(cycles: u32) {
    riscv::asm::delay(cycles / 2);
}
#[inline(always)]
pub fn delay_us(us: u32) {
    riscv::asm::delay((us * CORE_FREQ_MHZ) / 2);
}
#[inline(always)]
pub fn delay_ms(ms: u32) {
    riscv::asm::delay((ms * CORE_FREQ_KHZ) / 2);
}
#[inline(always)]
pub fn delay_sec(second: u32) {
    riscv::asm::delay((second * CORE_FREQ_HZ) / 2);
}

/// 官方的`riscv::register::mstatus::set_mie()`是**非原子**的\
/// 只能自己写一个替代品
#[inline(always)]
pub unsafe fn enable_global_interrupt() {
    unsafe { core::arch::asm!("csrsi mstatus, 0x8") }
}
/// 官方的`riscv::register::mstatus::clear_mie()`是**非原子**的\
/// 只能自己写一个替代品
#[inline(always)]
pub fn disable_global_interrupt() {
    unsafe { core::arch::asm!("csrci mstatus, 0x8") }
}

#[derive(Copy, Clone, PartialEq, Eq)]
#[repr(usize)]
pub enum ExternalInterrupt {
    Uart = 0,
    I2c1 = 8,
    I2c2 = 9,
    Spi = 10,
    Timer = 11,
    Wbcufm = 12,
}

unsafe impl riscv::InterruptNumber for ExternalInterrupt {
    const MAX_INTERRUPT_NUMBER: usize = Self::Wbcufm as usize + 16;

    #[inline]
    fn number(self) -> usize {
        self as usize + 16
    }

    #[inline]
    fn from_number(value: usize) -> riscv::result::Result<Self> {
        match value {
            val if val == Self::Uart as usize + 16 => Ok(Self::Uart),
            val if val == Self::I2c1 as usize + 16 => Ok(Self::I2c1),
            val if val == Self::I2c2 as usize + 16 => Ok(Self::I2c2),
            val if val == Self::Spi as usize + 16 => Ok(Self::Spi),
            val if val == Self::Timer as usize + 16 => Ok(Self::Timer),
            val if val == Self::Wbcufm as usize + 16 => Ok(Self::Wbcufm),
            _ => Err(riscv::result::Error::InvalidVariant(value)),
        }
    }
}

unsafe impl riscv::ExternalInterruptNumber for ExternalInterrupt {}

impl ExternalInterrupt {
    pub const fn into_mask(self) -> u32 {
        1u32 << (self as u32)
    }
}

/// csrw/csrs/csrc伪指令立即数支持
#[macro_export]
#[doc(hidden)]
macro_rules! csr_immediate {
    ($inst:literal, $csr:literal, $val:expr) => {
        if $val <= 0x1Fusize {
            core::arch::asm!(concat!($inst,"i ", $csr, ", {imm}"),
                imm = const $val,
                options(nomem, nostack)
            );
        } else {
            core::arch::asm!(concat!($inst," ", $csr, ", {val}"),
                val = in(reg) $val,
                options(nomem, nostack)
            );
        }
    };
}

#[macro_export]
macro_rules! write_csr {
    ($csr:literal, $val:expr) => {
        $crate::csr_immediate!("csrw", $csr, $val)
    };
}

#[macro_export]
macro_rules! set_csr {
    ($csr:literal, $val:expr) => {
        $crate::csr_immediate!("csrs", $csr, $val)
    };
}

#[macro_export]
macro_rules! clear_csr {
    ($csr:literal, $val:expr) => {
        $crate::csr_immediate!("csrc", $csr, $val)
    };
}

#[inline(always)]
pub unsafe fn enable_interrupt<const CODE: usize>() {
    unsafe { set_csr!("mie", (1usize << CODE)) }
}

#[inline(always)]
pub fn disable_interrupt<const CODE: usize>() {
    unsafe { clear_csr!("mie", (1usize << CODE)) }
}

#[inline(always)]
pub unsafe fn set_interrupt<const MASK: usize>() {
    unsafe { set_csr!("mie", MASK) }
}

#[inline(always)]
pub fn clear_interrupt<const MASK: usize>() {
    unsafe { clear_csr!("mie", MASK) }
}
