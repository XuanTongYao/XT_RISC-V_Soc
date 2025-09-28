.section .init
.global _start
_start:
    .option push
    .option norelax
1:  la sp, _sstack # 初始化栈指针
    auipc gp, %pcrel_hi(__global_pointer$)
    addi gp, gp, %pcrel_lo(1b)
    csrwi mscratch,0
    .option pop
    j main  # jump to main

