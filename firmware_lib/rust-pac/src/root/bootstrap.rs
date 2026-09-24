use crate::common::register::*;

#[repr(C)]
pub struct Bootstrap {
    /// 配置寄存器
    ///
    /// 读取得到启动引脚的值，0x01是下载模式，0x02是强制RAM模式暂停
    ///
    /// 写入0x00将指令区域映射到RAM
    /// 写入0x55将指令区域映射到ROM
    /// 写入任意有效值都会导致系统硬件复位
    pub config: RW<u8>,
    __: [u8; 3],
    /// 预载字符串地址。写入无效地址会导致preload寄存器硬件失效。
    pub preload_str_addr: WO<u8>,
    ___: [u8; 3],
    /// 预载字符串数据。读取会导致地址自增。
    pub preload_str_auto_inc: RO<u8>,
}

pub type InstanceBootstrap = RegisterBlock<Bootstrap>;
