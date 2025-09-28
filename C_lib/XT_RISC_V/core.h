#define CORE_FREQ_MHZ 12


//----------中断控制宏----------//
// ！！！永远不应该在中断处理函数中使用 中断控制宏
#define ENABLE_GLOBAL_MINT asm("csrsi mstatus, 0x8");
#define DISABLE_GLOBAL_MINT asm("csrci mstatus, 0x8");

// 下面执行前一定要先使用DISABLE_GLOBAL_MINT关闭全局中断
#define __SETTING_PREFIX asm("sw t0,-4(sp)");
#define __ENABLE_POSTFIX asm("csrs mie,t0"); asm("lw t0,-4(sp)");
#define __DISABLE_POSTFIX asm("csrc mie,t0"); asm("lw t0,-4(sp)");
#define __SETTING_MEI_IMM asm("li t0,0xFFFFF800");
#define __SETTING_MTI_IMM asm("li t0,0x00000080");
#define __SETTING_MSI_IMM asm("li t0,0x00000008");
#define __SETTING_ALL_IMM asm("li t0,0xFFFFF888");

#define ENABLE_ALL_MINT __SETTING_PREFIX; \
    __SETTING_ALL_IMM;\
    __ENABLE_POSTFIX;
#define ENABLE_MEI __SETTING_PREFIX; \
    __SETTING_MEI_IMM; \
    __ENABLE_POSTFIX;
#define ENABLE_MSI asm("csrsi mie,0x8");
#define ENABLE_MTI __SETTING_PREFIX; \
    __SETTING_MTI_IMM; \
    __ENABLE_POSTFIX;

#define DISABLE_ALL_MINT __SETTING_PREFIX; \
    __SETTING_ALL_IMM;\
    __DISABLE_POSTFIX;
#define DISABLE_MEI __SETTING_PREFIX; \
    __SETTING_MEI_IMM; \
    __DISABLE_POSTFIX;
#define DISABLE_MSI asm("csrci mie,0x8");
#define DISABLE_MTI __SETTING_PREFIX; \
    __SETTING_MTI_IMM; \
    __DISABLE_POSTFIX;


// 环境调用指令
#define ECALL asm("ecall");
// 异常处理完成(mepc+4)
#define EXCEPTION_DONE asm("csrrw t1, mepc, t1");\
    asm("addi t1, t1, 4");\
    asm("csrrw t1, mepc, t1");
// 异常处理失败
#define EXCEPTION_FAILED asm("j UnhandledFault");
// 暂停直到中断
#define WFI asm("wfi");
// 使用nop粗略延时
// nop->addi->bnez->if_id->id_ie->nop
// 频率除以5
#define __DELAY_SEC_TIMES (1000000*CORE_FREQ_MHZ/5)
#define __DELAY_MS_TIMES (1000*CORE_FREQ_MHZ/5)
#define __DELAY_10US_TIMES (10*CORE_FREQ_MHZ/5)
#define DELAY_NOP_SEC(SEC) for (size_t i = 0; i < (SEC)*__DELAY_SEC_TIMES; i++) {asm("nop");}
#define DELAY_NOP_MS(MS) for (size_t i = 0; i < (MS)*__DELAY_MS_TIMES; i++) {asm("nop");}
#define DELAY_NOP_10US(_10US) for (size_t i = 0; i < (_10US)*__DELAY_10US_TIMES; i++) {asm("nop");}
#define NOP asm("nop");


