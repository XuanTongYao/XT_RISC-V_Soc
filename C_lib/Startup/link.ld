OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
INST_RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x1000
DATA_RAM (rwx) : ORIGIN = 0x00001000, LENGTH = 0x1000
}
PROVIDE(__inst_origin = ORIGIN(INST_RAM));
PROVIDE(__inst_length = LENGTH(INST_RAM));
PROVIDE(__data_origin = ORIGIN(DATA_RAM));
PROVIDE(__data_length = LENGTH(DATA_RAM));

PROVIDE(__stack_size = 512);

SECTIONS
{
    .text :
    {
        KEEP (*(SORT_NONE(.init)))
        KEEP (*(SORT_NONE(.trap.vector)))
        KEEP (*(SORT_NONE(.trap.delete_handler)))
        KEEP (*(SORT_NONE(.trap.error_handler)))
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

    __peripheral_base = _sstack;

    _end = .;
}

