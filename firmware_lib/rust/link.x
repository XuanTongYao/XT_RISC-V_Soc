OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/* 查看默认链接脚本 */
/* riscv-none-elf-ld "--verbose" *> default.ld */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x2000
}
PROVIDE(__ram_origin = ORIGIN(RAM));
PROVIDE(__ram_length = LENGTH(RAM));

PROVIDE(__stack_size = 512);

SECTIONS
{
    .text :
    {
        KEEP (*(SORT_NONE(.init)))
        __TRAP_VECTOR__ = .;
        KEEP (*(SORT_NONE(.trap.vector)))
        KEEP (*(SORT_NONE(.trap.delete_handler)))
        KEEP (*(SORT_NONE(.trap.error_handler)))
        *(.text .text.*)
    } > RAM


    . = ALIGN(4);
    .rodata : 
    {
        *(.srodata .srodata.*)
        *(.rodata .rodata.*)
    } > RAM

    .data           :
    {
        __DATA_BEGIN__ = .;
        *(.data .data.*)
    } > RAM
    .sdata          :
    {
        __SDATA_BEGIN__ = .;
        *(.sdata .sdata.* .sdata2 .sdata2.*)
    } > RAM

    . = ALIGN(4);
    __BSS_START__ = .;
    .bss :
    {
        *(.sbss .sbss.* .scommon)
        *(.bss .bss.*)
        *(COMMON)
    } > RAM
    . = ALIGN(4);
    __BSS_END__ = .;

    _sstack = ORIGIN(RAM) + LENGTH(RAM);
    _estack = _sstack - __stack_size;
    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
        MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));


    _end = .;
}

