OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
INST_RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x800
DATA_RAM (rwx) : ORIGIN = 0x00000800, LENGTH = 0x800
}
PROVIDE(__stack_size = 512);

SECTIONS
{
    .text :
    {
        KEEP (*(SORT_NONE(.init)))
        *(.text)
        *(.text.*)
    } > INST_RAM


    . = ALIGN(4);
    .rodata : 
    {
        *(.rodata .rodata.*) 
    } > DATA_RAM

    .data           :
    {
        __DATA_BEGIN__ = .;
        *(.data .data.* .gnu.linkonce.d.*)
        SORT(CONSTRUCTORS)
    } > DATA_RAM
    .sdata          :
    {
        __SDATA_BEGIN__ = .;
        *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
        *(.sdata .sdata.* .gnu.linkonce.s.*)
    } > DATA_RAM

    .bss :
    {
        *(.sbss)
        *(.bss)
        __BSS_END__ = .;
        *(COMMON)
    } > DATA_RAM

    _sstack = ORIGIN(DATA_RAM) + LENGTH(DATA_RAM);
    _estack = _sstack - __stack_size;
    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
        MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));

    _end = .;
}

