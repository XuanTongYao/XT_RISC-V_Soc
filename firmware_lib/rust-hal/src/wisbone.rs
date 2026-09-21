//! WISHBONE总线外设，主要是FPGA芯片的嵌入式硬核

use crate::pac::common::register::RegisterBlock;
use crate::pac::get_top;
use crate::pac::root::efb_int_source;
use crate::pac::root::flash;
use crate::pac::root::i2c;
use crate::pac::root::spi;
use crate::pac::root::timer;
use xt_riscv_mcu::rv_core;

pub const FREQ_HZ: u32 = rv_core::CORE_FREQ_HZ;

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

pub use xt_rv32i_pac::root::i2c::{i2c_interrupt::I2cInterrupt, status::Status as I2cStatus};
type InstanceI2c = RegisterBlock<i2c::I2c>;
pub struct I2C {
    inst: InstanceI2c,
    /// 延迟的时间必须为(0,6)个I2C时钟周期
    /// 此处保存的是处理器时钟周期
    write_delay_cycles: u16,
    /// 延迟的时间必须为(2,7)个I2C时钟周期
    /// 此处保存的是处理器时钟周期
    read_delay_cycles: u16,
}

impl I2C {
    pub const PRESCALE_MASK: u16 = 0x3FF;

    pub unsafe fn primary() -> Self {
        Self::init(unsafe { get_top().i2c1() }, None)
    }
    pub unsafe fn secondary() -> Self {
        Self::init(unsafe { get_top().i2c2() }, None)
    }
    pub fn init(inst: InstanceI2c, prescale: Option<u16>) -> Self {
        let prescale = if let Some(prescale) = prescale {
            prescale & Self::PRESCALE_MASK
        } else {
            let low = inst.regs().br0.read() as u16;
            ((inst.regs().br1.read().into_bits() as u16) << 8) | low
        };
        Self {
            inst,
            write_delay_cycles: prescale,
            read_delay_cycles: prescale * 3,
        }
    }

    crate::prop_value!(status, status, I2cStatus, get);
    crate::prop_value!(general_call_data, general_call_data, u8, get);
    crate::prop_value!(int_status, int_status, I2cInterrupt, get, set);
    crate::prop_value!(int_en, int_en, I2cInterrupt, get, set);

    pub fn prescale(&self) -> u16 {
        let low = self.inst.regs().br0.read() as u16;
        ((self.inst.regs().br1.read().into_bits() as u16) << 8) | low
    }

    /// 设置预分频为 `div`，实际频率为`WISHBONE/(div*4)`
    /// - **主机**模式时，范围 `[0,1023]`
    /// - **从机**模式时，范围 `[0,512]`
    /// # Warning
    /// 重设预分频会使I2C复位
    pub fn set_prescale(&mut self, div: u16) {
        let div = div & Self::PRESCALE_MASK;
        self.inst.regs().br0.write(div as u8);
        self.inst.regs().br1.write(((div >> 8) as u8).into());
        self.write_delay_cycles = div;
        self.read_delay_cycles = div * 3;
    }

    #[inline(always)]
    pub fn reset(&mut self) {
        self.inst.regs().control.modify(|con| con.with_i2cen(false));
        // NOTE 原始C代码，出于未知原因在这里延迟了50us，如果出现问题请加回来
        self.inst.regs().control.modify(|con| con.with_i2cen(true));
    }

    /// 启动传输并进入**写入模式**
    pub fn master_start_transmission_block(&mut self, addr: u8) {
        self.inst.regs().tx_data.write(addr & 0xFE); // `& 0xFE`表示写操作，I2C协议决定的
        self.inst.regs().command.write(0x94.into());
        rv_core::delay(self.write_delay_cycles as u32); // 等(0,6)个I2C时钟周期
    }

    /// 从**写入模式**切换为**读取模式**\
    /// 必须处于**写入模式**中才能调用此函数
    pub fn master_into_read_block(&mut self, addr: u8) {
        self.inst.regs().tx_data.write(addr | 0x01); // `| 0x01`表示读操作，I2C协议决定的
        self.inst.regs().command.write(0x94.into());
        while !self.inst.regs().status.read().srw() {}
        self.inst.regs().command.write(0x24.into());
    }

    /// 必须处于**写入模式**中才能调用此函数
    pub fn master_write_byte_block(&mut self, byte: u8) {
        self.inst.regs().tx_data.write(byte);
        self.inst.regs().command.write(0x14.into());
        rv_core::delay(self.write_delay_cycles as u32); // 等(0,6)个I2C时钟周期
    }

    /// 必须处于**写入模式**中才能调用此函数
    pub fn master_write_block(&mut self, data: &[u8]) {
        for byte in data {
            self.master_write_byte_block(*byte);
        }
    }

    /// 必须处于**读取模式**中才能调用此函数
    /// # Warning
    /// **不能**读取到最后一个字节！最后一个字节只能使用`master_finish_read_block`来获取
    pub fn master_read_byte_block(&mut self) -> u8 {
        while !self.inst.regs().status.read().trrdy() {}
        self.inst.regs().rx_data.read()
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
        self.inst.regs().command.write(0x44.into())
    }

    /// 从**读取模式**结束传输\
    /// 会返回最后一个读取到的字节
    pub fn master_finish_read_block(&mut self) -> u8 {
        rv_core::delay(self.read_delay_cycles as u32); // 等(2,7)个I2C时钟周期
        self.inst.regs().command.write(0x6C.into());
        let last_byte = self.master_read_byte_block();
        self.inst.regs().command.write(0x04.into());
        last_byte
    }
}

pub use spi::control2::Control2 as SpiControl2;
type InstanceSpi = RegisterBlock<spi::Spi>;
pub struct Spi {
    inst: InstanceSpi,
}
impl Spi {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().spi() })
    }
    pub fn new(inst: InstanceSpi) -> Self {
        Self { inst }
    }

    crate::prop_value!(control2, control2, SpiControl2, get, set, modify);
    crate::getset_field!(master_mode, control2, mstr, bool);
    crate::getset_field!(polarity_active_low, control2, cpol, bool);
    crate::getset_field!(phase_second_edge, control2, cpha, bool);
    crate::getset_field!(lsb_first, control2, lsbf, bool);

    crate::prop_value!(cs, cs, u8, get, set);

    crate::prop_value!(
        /// 获取预分频`div`，实际频率为`WISHBONE/(div+1)`
        prescale,
        clock_prescale,
        u8,
        get
    );

    /// 设置预分频为 `div` 范围 `[1,63]`，实际频率为`WISHBONE/(div+1)`
    /// # Warning
    /// 重设预分频会使SPI复位
    #[inline(always)]
    pub fn set_prescale(&mut self, div: u8) {
        if div != 0 {
            self.inst.regs().clock_prescale.write(div)
        }
    }

    pub fn master_start_rw_block(&mut self, byte: u8) -> u8 {
        self.inst.regs().control2.write(0xC0.into());
        while !self.inst.regs().status.read().trdy() {}
        self.master_rw_byte_block(byte)
    }

    /// 调用`master_start_rw_block`后才能使用此函数执行读写操作
    #[inline]
    pub fn master_rw_byte_block(&mut self, byte: u8) -> u8 {
        self.inst.regs().tx_data.write(byte);
        while !self.inst.regs().status.read().rrdy() {}
        self.inst.regs().rx_data.read()
    }

    /// 调用`master_start_rw_block`后才能使用此函数
    #[inline]
    pub fn master_finish_rw_block(&mut self) {
        self.inst.regs().control2.write(0x80.into());
        while self.inst.regs().status.read().tip() {}
    }

    pub fn slave_restart_rw_block(&mut self, byte0: u8, byte1: u8) -> u8 {
        let reg = self.inst.regs();
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

    /// 调用`slave_restart_rw_block`后才能使用此函数执行读写操作
    pub fn slave_rw_byte_block(&mut self, next_byte: u8) -> u8 {
        let reg = self.inst.regs();
        while !reg.status.read().trdy() {}
        reg.tx_data.write(next_byte);
        while !reg.status.read().rrdy() {}
        reg.rx_data.read()
    }
}

pub use timer::control0::{Control0 as TimerControl0, TimerClkSel, TimerDivider};
pub use timer::control1::{Control1 as TimerControl1, TimerCounterMode, TimerOutputMode};
pub use timer::timer_interrupt::TimerInterrupt;
type InstanceTimer = RegisterBlock<timer::Timer>;
pub struct Timer {
    inst: InstanceTimer,
}
impl Timer {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().timer() })
    }
    pub fn new(inst: InstanceTimer) -> Self {
        Self { inst }
    }
    get_u16_from_2_u8!(top, [toph, topl]);
    get_u16_from_2_u8!(compare, [compareh, comparel]);
    get_u16_from_2_u8!(counter, [counterh, counterl]);
    get_u16_from_2_u8!(capture, [captureh, capturel]);

    #[inline(always)]
    pub fn set_top(&mut self, value: u16) {
        self.inst.regs().top_setl.write(value as u8);
        self.inst.regs().top_seth.write((value >> 8) as u8);
    }
    #[inline(always)]
    pub fn set_compare(&mut self, value: u16) {
        self.inst.regs().compare_setl.write(value as u8);
        self.inst.regs().compare_seth.write((value >> 8) as u8);
    }

    crate::prop_value!(control0, control0, TimerControl0, get, set);
    crate::prop_value!(control1, control1, TimerControl1, get, set);

    crate::getset_field!(clk_source, control0, clksel, TimerClkSel);
    crate::getset_field!(
        /// 用于设置时钟源的有效沿
        active_negedge,
        control0,
        clkedge,
        bool
    );
    crate::getset_field!(prescale, control0, prescale, TimerDivider);
    crate::getset_field!(reset_signal_enabled, control0, rsten, bool);

    crate::getset_field!(counter_mode, control1, tcm, TimerCounterMode);
    crate::getset_field!(output_mode, control1, ocm, TimerOutputMode);
    crate::getset_field!(
        /// 启用自动重装载
        autoload,
        control1,
        tsel,
        bool
    );
    crate::getset_field!(
        /// 启用输入捕获
        input,
        control1,
        icen,
        bool
    );

    crate::getset_field!(paused, control2, wbpause, bool);
    crate::getset_field!(
        /// 重置定时器(必须等待至少两个周期后将该位手动恢复到0)
        reseted,
        control2,
        wbreset,
        bool
    );
    crate::getset_field!(
        /// 非PWM模式强制输出，当定时器匹配或到达周期时
        output_in_non_pwm,
        control2,
        wbforce,
        bool
    );

    crate::prop_value!(int_status, int_status, TimerInterrupt, get, set);
    crate::prop_value!(int_en, int_en, TimerInterrupt, get, set, modify);
}

type InstanceFlash = RegisterBlock<flash::Flash>;
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
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().flash() })
    }
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
type InstanceEfbIntSource = RegisterBlock<efb_int_source::EfbIntSource>;
/// 指示EFB中断来源于什么
pub struct EfbIntSource {
    inst: InstanceEfbIntSource,
}
impl EfbIntSource {
    pub unsafe fn singleton() -> Self {
        Self::new(unsafe { get_top().efbintsource() })
    }
    pub fn new(inst: InstanceEfbIntSource) -> Self {
        Self { inst }
    }

    crate::prop_value!(source, source, EfbIntFlags, get);
}
