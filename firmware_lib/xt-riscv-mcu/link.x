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
        KEEP (*(SORT_NONE(.init.clear_bss)))
        KEEP (*(SORT_NONE(.init.trap)))
        KEEP (*(SORT_NONE(.init.call_main)))
        __TRAP_VECTOR__ = .;
        KEEP (*(SORT_NONE(.trap.vector)))
        KEEP (*(SORT_NONE(.trap.delete_handler)))
        *(.text .text.*)
    } > RAM


    .rodata ALIGN(4) : 
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

    .bss ALIGN(4) :
    {
        __BSS_START__ = .;
        *(.sbss .sbss.* .scommon)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __BSS_END__ = .;
    } > RAM

    _sstack = ORIGIN(RAM) + LENGTH(RAM);
    _estack = _sstack - __stack_size;
    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
        MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));


    _end = .;
}

