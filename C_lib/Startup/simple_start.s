.section .init
.global _start
_start:
    .option push
    .option norelax
1:  auipc gp, %pcrel_hi(__global_pointer$)
    addi gp, gp, %pcrel_lo(1b)
    .option pop
    lla sp, _sstack # 初始化栈指针
    call main  # jump to main

