pub const FLASH_BASE: u32 = 0;
pub const PAGE_SIZE: usize = 16;
pub const FLASH_SIZE: u32 = 767 * 16; // 0x2FF0
pub const PROGRAM_TIMEOUT_MS: u32 = 20;
pub const ERASE_TIMEOUT_MS: u32 = 2000;

const CTRL: *mut u8 = 0x3070 as *mut u8;
const TX: *mut u8 = 0x3071 as *mut u8;

pub const CORE_FREQ_MHZ: u32 = 12;
pub const CORE_FREQ_KHZ: u32 = CORE_FREQ_MHZ * 1000;

// Flash命令
pub const ISC_NOOP: u8 = 0xFF;
pub const ISC_ENABLE_X: u8 = 0x74;
pub const ISC_DISABLE: u8 = 0x26;
pub const LSC_WRITE_ADDRESS: u8 = 0xB4;

// UFM扇区特有命令
#[allow(dead_code)]
pub const LSC_INIT_ADDR_UFM: u8 = 0x47; // 重置UFM地址
#[allow(dead_code)]
pub const LSC_READ_TAG: u8 = 0xCA;
pub const LSC_ERASE_TAG: u8 = 0xCB;
pub const LSC_PROG_TAG: u8 = 0xC9;

#[inline(always)]
fn tx(b: u8) {
    unsafe { TX.write_volatile(b) }
}
#[inline(always)]
fn ctrl(b: u8) {
    unsafe { CTRL.write_volatile(b) }
}

#[inline]
fn command(f: impl FnOnce()) {
    ctrl(0x80);
    f();
    ctrl(0x00);
}

macro_rules! flash_write {
    ( $($byte:expr),+) => {
        {
            $( tx($byte); )*
        }
    };
}

fn delay_us(us: u32) {
    riscv::asm::delay((us * CORE_FREQ_MHZ) / 2);
}

fn delay_ms(ms: u32) {
    riscv::asm::delay((ms * CORE_FREQ_KHZ) / 2);
}

pub fn init() {
    ctrl(0x40);
    command(|| flash_write!(ISC_ENABLE_X, 0x08, 0, 0));
    delay_us(8);
}

pub fn uninit() {
    command(|| flash_write!(ISC_DISABLE, 0, 0));
    command(|| flash_write!(ISC_NOOP));
}

fn set_ufm_addr(page: u16) {
    let page = page & 0x3FFF;
    command(|| {
        flash_write!(LSC_WRITE_ADDRESS, 0, 0, 0);
        tx(0x40);
        tx(0x00);
        tx((page >> 8) as u8);
        tx(page as u8);
    });
}

fn write_one_page(ptr: *const u8) {
    command(|| unsafe {
        flash_write!(LSC_PROG_TAG, 0x00, 0x00, 0x01);
        let mut p = ptr;
        for _ in 0..PAGE_SIZE {
            tx(*p);
            p = p.add(1);
        }
    });
    delay_us(210);
}

pub fn erase_all() {
    command(|| flash_write!(LSC_ERASE_TAG, 0, 0, 0));
    delay_ms(1050);
}

pub fn program(address: u32, data: &[u8]) {
    set_ufm_addr((address / PAGE_SIZE as u32) as u16);
    let mut ptr = data.as_ptr();
    let mut left = data.len();
    while left >= PAGE_SIZE {
        write_one_page(ptr);
        ptr = unsafe { ptr.add(PAGE_SIZE) };
        left -= PAGE_SIZE;
    }
}
