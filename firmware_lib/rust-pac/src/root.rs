pub mod bootstrap;
pub mod efb_int_source;
pub mod eint_controller;
pub mod flash;
pub mod gpio;
pub mod i2c;
pub mod key_switch;
pub mod led;
pub mod ledsd;
pub mod msip;
pub mod mtime;
pub mod spi;
pub mod timer;
pub mod uart;
pub mod xt_rv32i;

use crate::common::register::RegisterBlock;
use xt_rv32i::XtRv32i;

/// 基于 RISC-V RV32I 架构的微控制器, CPU频率为12MHz
pub const unsafe fn get_top() -> RegisterBlock<XtRv32i> {
    unsafe { RegisterBlock::<XtRv32i>::from_ptr(0 as _) }
}
