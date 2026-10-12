OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/* 查看默认链接脚本 */
/* riscv-none-elf-ld "--verbose" *> default.ld */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x2000
}

PROVIDE(__stack_size = 512);
_stack_start = ORIGIN(RAM) + LENGTH(RAM);
ASSERT(SIZEOF(.stack) >= __stack_size, "Error(xt-riscv-mcu): No room left for the stack");

SECTIONS
{
    .text :
    {
        KEEP (*(SORT_NONE(.init)))
        KEEP (*(SORT_NONE(.init.clear_bss)))
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

    .data :
    {
        __DATA_BEGIN__ = .;
        *(.data .data.*)
    } > RAM
    .sdata :
    {
        __SDATA_BEGIN__ = .;
        *(.sdata .sdata.* .sdata2 .sdata2.*)
    } > RAM

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

    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
        MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));


    _end = .;
}

