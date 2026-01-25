// 包含了常用的内联汇编宏


#define NOP asm("nop")
// 环境调用指令
#define ECALL asm("ecall")
// 暂停直到中断
#define WFI asm("wfi")

//----------CSR操作宏----------//
#define SWAP_CSR(reg,lvalue,val) asm volatile("csrrw %0, " #reg ", %1" : "=r"(lvalue) : "rK"(val))
#define READ_CSR(reg,lvalue) asm volatile("csrr %0, " #reg : "=r"(lvalue))
#define WRITE_CSR(reg,val) asm volatile("csrw " #reg ", %0"  :: "rK"(val))
#define SET_CSR(reg,val) asm volatile("csrs " #reg ", %0"  :: "rK"(val))
#define CLEAR_CSR(reg,val) asm volatile("csrc " #reg ", %0"  :: "rK"(val))



//----------快捷异常处理----------//
// 跳过异常(mepc+4)
#define EXCEPTION_SKIP \
asm volatile("csrr %0, mepc\n"\
    "addi %0, %0, 4\n"\
    "csrw mepc, %0"\
    : "=r"((unsigned long) {0}))
// 异常处理失败
#define EXCEPTION_FAILED asm("j UnhandledFault")



//----------中断控制----------//
// ！！！永远不应该在中断处理函数中使用 中断控制宏
#define ENABLE_GLOBAL_MINT asm("csrsi mstatus, 0x8")
#define DISABLE_GLOBAL_MINT asm("csrci mstatus, 0x8")

#define ALL_INT_MASK 0xFFFFF888
#define MEI_MASK 0xFFFFF800
#define MTI_MASK 0x00000080
#define MSI_MASK 0x00000008

// 下面执行前一定要先使用DISABLE_GLOBAL_MINT关闭全局中断
#define ENABLE_INT(MASK) ({\
    unsigned long __tmp=MASK;\
    SET_CSR(mie, __tmp);\
})

#define DISABLE_INT(MASK) ({\
    unsigned long __tmp=MASK;\
    CLEAR_CSR(mie, __tmp);\
})

#define ENABLE_ALL_MINT ENABLE_INT(ALL_INT_MASK)
#define ENABLE_MEI ENABLE_INT(MEI_MASK)
#define ENABLE_MSI ENABLE_INT(MTI_MASK)
#define ENABLE_MTI ENABLE_INT(MSI_MASK)

#define DISABLE_ALL_MINT DISABLE_INT(ALL_INT_MASK)
#define DISABLE_MEI DISABLE_INT(MEI_MASK)
#define DISABLE_MSI DISABLE_INT(MTI_MASK)
#define DISABLE_MTI DISABLE_INT(MSI_MASK)


