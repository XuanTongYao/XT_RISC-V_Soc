OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/* 查看默认链接脚本 */
/* riscv-none-elf-ld "--verbose" *> default.ld */

/* .data 复位后没有重置的问题 
解决方法1:  预留一个与.data大小相同的输出段，llvm的链接器允许你将LMA设为这个段的起始地址。在gcc gold中会报错。
解决方法2:  把.data加载地址放到超出RAM大小的区域（Flash还剩下4080 Bytes），启动时加载
            当.data段大于236字节时，才有实际收益
解决方法3:  ROM与RAM不使用同样的地址，能随意切换从ROM或RAM读取指令
 */
/* 当前使用 解决方法2 */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x2000
}

PROVIDE(__stack_size = 512);
_stack_start = ORIGIN(RAM) + LENGTH(RAM);
ASSERT(SIZEOF(.stack) >= __stack_size, "Error(xt-riscv-mcu): No room left for the stack");
ASSERT(SIZEOF(.data) <= 0xFF0, "Error(xt-riscv-mcu): `.data` exceeds FLASH");


PROVIDE(_flash_load_skip = 0);
PROVIDE(_flash_load = 0);
SECTIONS
{
    .text :
    {
        KEEP (*(SORT_NONE(.init)))
        KEEP (*(SORT_NONE(.init.data_and_bss)))
        KEEP (*(SORT_NONE(.init.trap)))
        KEEP (*(SORT_NONE(.init.call_main)))
        KEEP (*(SORT_NONE(.trap.vector)))
        KEEP (*(SORT_NONE(.trap.default_handler)))
        *(.text .text.*)
    } > RAM


    .rodata : ALIGN(4)
    {
        *(.srodata .srodata.*)
        *(.rodata .rodata.*)
    } > RAM

    /* 解决方法1 */
    /* AT(ADDR(.data) + SIZEOF(.data)) */
    .data : AT(ORIGIN(RAM) + LENGTH(RAM)) ALIGN(16)
    {
        __DATA_BEGIN__ = .;
        *(.data .data.*)
        *(.sdata .sdata.* .sdata2 .sdata2.*)
        . = ALIGN(16);
        __DATA_END__ = .;
    } > RAM
    __DATA_LOAD_START__ = LOADADDR(.data);
    _load_data_entry = (__DATA_END__ == __DATA_BEGIN__) 
                    ? _flash_load_skip 
                    : _flash_load;

    /* 解决方法1 */
    /* .data_load (NOLOAD) : ALIGN(16)
    {
        . =  ADDR(.data) + (SIZEOF(.data)*2);
    } > RAM */

    .bss : ALIGN(4)
    {
        __BSS_START__ = .;
        *(.sbss .sbss.* .scommon)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __BSS_END__ = .;
    } > RAM

    /* 真正未初始化（无需初始化）段 */
    .uninit (NOLOAD) : ALIGN(4)
    {
        *(.uninit .uninit.*);
    } > RAM

    .stack (NOLOAD) : ALIGN(16)
    {
        _stack_end = .;
        . = ABSOLUTE(_stack_start);
    } > RAM

    /* 设置为尽量覆盖.bss段的地址 */
    __global_pointer$ 
        = MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800);


    _end = .;
}

