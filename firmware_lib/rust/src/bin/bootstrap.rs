#![no_std]
#![no_main]

use xt_riscv_mcu::entry;
use xt_riscv_mcu::hb32::BootstrapPreloadStr;
use xt_riscv_mcu::hb32::{Bootstrap, Uart};
use xt_riscv_mcu::wisbone::Flash;

const MAX_TEXT_DATA_LEN: usize = 4096 + 4096 - 512;

#[entry]
fn main() -> ! {
    let buffer_word = [0u32; 4]; // 这里是为了32bit对齐
    let buffer = unsafe { core::mem::transmute::<[u32; 4], [u8; 16]>(buffer_word) };
    let mut flash = Flash::SINGLETON;
    let bootstrap = Bootstrap::SINGLETON;
    let uart = Uart::SINGLETON;
    flash.reset();
    flash.enable_transparent_ufm();
    if bootstrap.is_download_mode() {
        download(flash, uart, bootstrap, buffer);
    } else {
        boot(flash, uart, bootstrap, buffer);
    }
}

fn boot(mut flash: Flash, mut uart: Uart, mut bootstrap: Bootstrap, mut buffer: [u8; 16]) -> ! {
    flash.reset_ufm_addr();
    let buffer_word = unsafe { core::mem::transmute::<[u8; 16], [u32; 4]>(buffer) };
    let mut inst_ptr = 0usize as *mut u32;
    for _ in 0..(MAX_TEXT_DATA_LEN >> 4) {
        flash.read_one_ufm_page(&mut buffer);
        for word in buffer_word {
            unsafe {
                inst_ptr.write_volatile(word);
                inst_ptr = inst_ptr.add(1);
            }
        }
    }

    // 首个指令全为0，则为无效代码
    unsafe {
        let first_inst = (0usize as *mut u32).read_volatile();
        if first_inst == 0 {
            loop {
                block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::ERR)
            }
        }
    }

    unsafe { bootstrap.into_ram_mode() }
    loop {}
}

fn download(mut flash: Flash, mut uart: Uart, mut bootstrap: Bootstrap, mut buffer: [u8; 16]) -> ! {
    let mut page_num;
    loop {
        if !uart.has_data() {
            block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::CMD);
            continue;
        }
        let uart_cmd = unsafe { uart.rx_forced() };
        if uart_cmd != 0x56 {
            continue;
        }

        // 进入下载模式
        loop {
            block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::LEN);
            page_num = (uart.rx_block() as usize) << 8;
            page_num |= uart.rx_block() as usize;
            if page_num > Flash::TOTAL_PAGE || page_num == 0 {
                continue;
            }
            break;
        }
        // 确认
        block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::START_DOWNLOAD);
        while 0x78 != uart.rx_block() {}
        // 擦除
        flash.erase_ufm();
        from_uart_download(&mut flash, &mut uart, &mut buffer, page_num);
        // 完成确认
        block_print_auto_increment(&mut uart, &mut bootstrap, Bootstrap::CONFIRM);
        while 0x57 != uart.rx_block() {}
    }
}

fn from_uart_download(flash: &mut Flash, uart: &mut Uart, buffer: &mut [u8; 16], pages: usize) {
    flash.reset_ufm_addr();
    for _ in 0..pages {
        uart.rx_bytes_into_block(buffer);
        flash.write_one_ufm_page(buffer);
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
