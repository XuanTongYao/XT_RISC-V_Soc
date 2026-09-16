use crate::common::register::*;

#[repr(C)]
pub struct Mtime {
    /// mtime 低32位。 设置不当可能会立即引发定时器中断。
    pub mtimel: RW<u32>,
    /// mtime 高32位。 设置不当可能会立即引发定时器中断。
    pub mtimeh: RW<u32>,
    /// mtimecmp 低32位。 设置不当可能会立即引发定时器中断。
    pub mtimecmpl: RW<u32>,
    /// mtimecmp 高32位。 设置不当可能会立即引发定时器中断。
    pub mtimecmph: RW<u32>,
}
