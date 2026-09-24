use super::bootstrap::Bootstrap;
use super::efb_int_source::EfbIntSource;
use super::eint_controller::EintController;
use super::flash::Flash;
use super::gpio::Gpio;
use super::i2c::I2c;
use super::key_switch::KeySwitch;
use super::led::Led;
use super::ledsd::Ledsd;
use super::msip::Msip;
use super::mtime::Mtime;
use super::spi::Spi;
use super::timer::Timer;
use super::uart::Uart;
use crate::common::register::*;

pub struct XtRv32i;

pub type InstanceXtRv32i = RegisterBlock<XtRv32i>;

impl RegisterBlock<XtRv32i> {
    /// 自举控制器
    #[inline(always)]
    pub const unsafe fn bootstrap(&self) -> RegisterBlock<Bootstrap> {
        unsafe { RegisterBlock::<Bootstrap>::from_ptr(self.as_ptr().wrapping_byte_add(0x2000)) }
    }
    /// 外部中断控制器。对大于等于16的自定义中断进行硬件重定向。
    #[inline(always)]
    pub const unsafe fn eintcontroller(&self) -> RegisterBlock<EintController> {
        unsafe {
            RegisterBlock::<EintController>::from_ptr(self.as_ptr().wrapping_byte_add(0x2020))
        }
    }
    /// RISC-V M模式定时器寄存器。 频率为 1 MHz。 64位的 mtime 和 mtimecmp 被分成多个高低位32位寄存器。
    #[inline(always)]
    pub const unsafe fn mtime(&self) -> RegisterBlock<Mtime> {
        unsafe { RegisterBlock::<Mtime>::from_ptr(self.as_ptr().wrapping_byte_add(0x2040)) }
    }
    /// UART. 波特率19200.
    #[inline(always)]
    pub const unsafe fn uart(&self) -> RegisterBlock<Uart> {
        unsafe { RegisterBlock::<Uart>::from_ptr(self.as_ptr().wrapping_byte_add(0x2060)) }
    }
    /// RISC-V M模式软件中断寄存器
    #[inline(always)]
    pub const unsafe fn msoftwareint(&self) -> RegisterBlock<Msip> {
        unsafe { RegisterBlock::<Msip>::from_ptr(self.as_ptr().wrapping_byte_add(0x2080)) }
    }
    /// GPIO。 只有0-27共28个GPIO，超出的部分会被硬件自动忽略。
    #[inline(always)]
    pub const unsafe fn gpio(&self) -> RegisterBlock<Gpio> {
        unsafe { RegisterBlock::<Gpio>::from_ptr(self.as_ptr().wrapping_byte_add(0x20A0)) }
    }
    /// WISHBONE 主 I2C (I2C1). 实际频率为 `WISHBONE/(div*4)`. 预分频范围 [0,1023]. 写入 `CONTROL` 或 `BR1` 将导致I2C复位.
    #[inline(always)]
    pub const unsafe fn i2c1(&self) -> RegisterBlock<I2c> {
        unsafe { RegisterBlock::<I2c>::from_ptr(self.as_ptr().wrapping_byte_add(0x3040)) }
    }
    /// WISHBONE 次 I2C (I2C2). 寄存器布局与 I2C1 相同. 预分频范围 [0,512]
    #[inline(always)]
    pub const unsafe fn i2c2(&self) -> RegisterBlock<I2c> {
        unsafe { RegisterBlock::<I2c>::from_ptr(self.as_ptr().wrapping_byte_add(0x304A)) }
    }
    /// WISHBONE SPI. 实际时钟频率为 `WISHBONE/(div+1)`, 预分频范围 [1,63]. 设置预分频或主机片选会使SPI复位.
    #[inline(always)]
    pub const unsafe fn spi(&self) -> RegisterBlock<Spi> {
        unsafe { RegisterBlock::<Spi>::from_ptr(self.as_ptr().wrapping_byte_add(0x3054)) }
    }
    /// WISHBONE 16位定时器/计数器.
    #[inline(always)]
    pub const unsafe fn timer(&self) -> RegisterBlock<Timer> {
        unsafe { RegisterBlock::<Timer>::from_ptr(self.as_ptr().wrapping_byte_add(0x305E)) }
    }
    /// WISHBONE UFM / configuration flash interface. TOTAL_PAGE=767, PAGE_BYTES=16, PAGE_MASK=0x3FFF. Transparent UFM access temporarily disables power control, global set/reset, user SPI and user primary I2C.
    #[inline(always)]
    pub const unsafe fn flash(&self) -> RegisterBlock<Flash> {
        unsafe { RegisterBlock::<Flash>::from_ptr(self.as_ptr().wrapping_byte_add(0x3070)) }
    }
    /// 指示 EFB 中断来源于什么
    #[inline(always)]
    pub const unsafe fn efbintsource(&self) -> RegisterBlock<EfbIntSource> {
        unsafe { RegisterBlock::<EfbIntSource>::from_ptr(self.as_ptr().wrapping_byte_add(0x3077)) }
    }
    /// 按钮与开关，按下时为高电平(已经在硬件做了翻转)。
    #[inline(always)]
    pub const unsafe fn keyswitch(&self) -> RegisterBlock<KeySwitch> {
        unsafe { RegisterBlock::<KeySwitch>::from_ptr(self.as_ptr().wrapping_byte_add(0x4000)) }
    }
    /// LED
    #[inline(always)]
    pub const unsafe fn led(&self) -> RegisterBlock<Led> {
        unsafe { RegisterBlock::<Led>::from_ptr(self.as_ptr().wrapping_byte_add(0x4080)) }
    }
    /// 七段LED数码管
    #[inline(always)]
    pub const unsafe fn ledsd(&self) -> RegisterBlock<Ledsd> {
        unsafe { RegisterBlock::<Ledsd>::from_ptr(self.as_ptr().wrapping_byte_add(0x40C0)) }
    }
}
