#![no_std]
#![no_main]

mod flash;

use flash_algorithm::*;

struct Algorithm;

algorithm!(Algorithm, {
    device_name: "XT_RV32I",
    device_type: DeviceType::Onchip,
    flash_address: flash::FLASH_BASE,
    flash_size: flash::FLASH_SIZE,
    page_size: flash::PAGE_SIZE as u32,
    empty_value: 0x00,
    program_time_out: flash::PROGRAM_TIMEOUT_MS,
    erase_time_out: flash::ERASE_TIMEOUT_MS,
    sectors: [{
        size: flash::FLASH_SIZE,
        address: flash::FLASH_BASE,
    }]
});

impl FlashAlgorithm for Algorithm {
    fn new(_address: u32, _clock: u32, _function: Function) -> Result<Self, ErrorCode> {
        flash::init();
        Ok(Self)
    }

    fn erase_all(&mut self) -> Result<(), ErrorCode> {
        flash::erase_all();
        Ok(())
    }

    fn erase_sector(&mut self, _address: u32) -> Result<(), ErrorCode> {
        flash::erase_all();
        Ok(())
    }

    fn program_page(&mut self, address: u32, data: &[u8]) -> Result<(), ErrorCode> {
        flash::program(address, data);
        Ok(())
    }
}

impl Drop for Algorithm {
    fn drop(&mut self) {
        flash::uninit();
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
