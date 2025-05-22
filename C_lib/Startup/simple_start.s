.section .init
.global _start
_start:
    li sp, 4096 # 初始化栈指针
    # 全局指针gp用于优化±2KB内全局变量的访问
    # 它的位置应该是全局区+2KB
    li gp, 4164 # 初始化全局指针 0x1044
    j main  # jump to main

