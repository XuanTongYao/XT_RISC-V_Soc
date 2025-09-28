#ifndef TYPE_H
#define TYPE_H
#include <stdint.h>
#include <stddef.h>

// 内联汇编忽略
#ifdef VSCODE
#define asm(X)
#endif

#ifdef VSCODE
#define __attribute__(X)
#endif

// 指示函数为异常/中断处理函数，以便编译器正确保存并转移上下文
#define IRQ __attribute__((interrupt)) void



typedef volatile uint8_t* byte_reg_ptr;
typedef volatile uint16_t* half_reg_ptr;
typedef volatile uint32_t* word_reg_ptr;
typedef volatile uint64_t* dword_reg_ptr;
typedef const byte_reg_ptr      ro_byte_reg_ptr;
typedef const half_reg_ptr      ro_half_reg_ptr;
typedef const word_reg_ptr      ro_word_reg_ptr;
typedef const dword_reg_ptr     ro_dword_reg_ptr;
typedef volatile uint8_t* wo_byte_reg_ptr;
typedef volatile uint16_t* wo_half_reg_ptr;
typedef volatile uint32_t* wo_word_reg_ptr;
typedef volatile uint64_t* wo_dword_reg_ptr;

#endif
