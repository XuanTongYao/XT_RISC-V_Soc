#![no_std]
#![no_main]

use riscv_macros::entry;
use xt_rv32i_hal::hb32::BootstrapPreloadStr;
use xt_rv32i_hal::hb32::{Bootstrap, Uart};
use xt_rv32i_hal::wisbone::Flash;
use xt_rv32i_pac::get_top;

const MAX_TEXT_DATA_LEN: usize = 4096 + 4096 - 512; // 512是栈大小
const MAX_PAGES: usize = if (MAX_TEXT_DATA_LEN >> 4) < Flash::TOTAL_PAGE {
    MAX_TEXT_DATA_LEN >> 4
} else {
    Flash::TOTAL_PAGE
};

#[entry]
fn main() -> ! {
    let mut flash = unsafe { Flash::new(get_top().flash()) };
    let bootstrap = unsafe { Bootstrap::new(get_top().bootstrap()) };
    let uart = unsafe { Uart::new(get_top().uart()) };
    flash.reset();
    flash.enable_transparent_ufm();
    if bootstrap.ram_mode_stop() {
        unsafe {
            core::arch::asm!("csrw mtvec, x0");
            (0 as *mut u32).write_volatile(0);
        }
        boot_ram_mode(bootstrap);
    } else if bootstrap.download_mode() {
        download(flash, uart, bootstrap);
    } else {
        boot(flash, uart, bootstrap);
    }
}

fn boot(mut flash: Flash, mut uart: Uart, mut bootstrap: Bootstrap) -> ! {
    flash.reset_ufm_addr();
    let mut inst_ptr = 0 as *mut u8;
    for _ in 0..(MAX_TEXT_DATA_LEN >> 4) {
        unsafe { inst_ptr = flash.read_one_ufm_page_ptr(inst_ptr) }
    }

    // 首个指令全为0，则为无效代码
    unsafe {
        if (0 as *mut u32).read_volatile() == 0 {
            loop {
                block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::ERR)
            }
        }
    }

    boot_ram_mode(bootstrap)
}

fn boot_ram_mode(mut bootstrap: Bootstrap) -> ! {
    unsafe { bootstrap.into_ram_mode() }
    loop {}
}

fn download(mut flash: Flash, mut uart: Uart, mut bootstrap: Bootstrap) -> ! {
    let mut page_num;
    loop {
        if !uart.status().rx_end() {
            block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::CMD);
            continue;
        }
        let uart_cmd = uart.rx();
        if uart_cmd != 0x56 {
            continue;
        }

        // 进入下载模式
        loop {
            block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::LEN);
            page_num = (uart.rx_block() as usize) << 8;
            page_num |= uart.rx_block() as usize;
            if page_num > MAX_PAGES || page_num == 0 {
                continue;
            }
            break;
        }
        // 确认
        block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::START_DOWNLOAD);
        while 0x78 != uart.rx_block() {}
        // 擦除
        flash.erase_ufm();
        from_uart_download(&mut flash, &mut uart, page_num);
        // 完成确认
        block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::CONFIRM);
        while 0x57 != uart.rx_block() {}
    }
}

fn from_uart_download(flash: &mut Flash, uart: &mut Uart, pages: usize) {
    // 先全部接收到内存，再写入到Flash
    let mut ptr = 0 as *mut u8;
    for _ in 0..(pages * Flash::PAGE_BYTES) {
        unsafe {
            ptr.write_volatile(uart.rx_block());
            ptr = ptr.wrapping_add(1);
        }
    }

    let mut ptr = 0 as *const u8;
    flash.reset_ufm_addr();
    for _ in 0..pages {
        unsafe { ptr = flash.write_one_ufm_page_ptr(ptr) }
    }
}

fn block_print_auto_increment(
    uart: &mut Uart,
    bootstrap: &mut Bootstrap,
    preload_str: BootstrapPreloadStr,
) {
    unsafe { bootstrap.set_preload_str_addr(preload_str.addr) }
    for _ in 0..preload_str.len {
        uart.tx_block(bootstrap.get_preload_str_u8());
    }
}
