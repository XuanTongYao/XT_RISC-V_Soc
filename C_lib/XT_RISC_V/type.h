#ifndef TYPE_H
#define TYPE_H


// 内联汇编忽略
#ifdef VSCODE
#define asm(X)
#endif

#ifdef VSCODE
#define __attribute__(X)
#endif

// 指示函数为异常/中断处理函数，以便编译器正确保存并转移上下文
#define IRQ __attribute__((interrupt)) void

typedef signed char             int8_t;
typedef short                   int16_t;
typedef int                     int32_t;
typedef long long int           int64_t;
typedef unsigned char           uint8_t;
typedef unsigned short          uint16_t;
typedef unsigned int            uint32_t;
typedef unsigned long long int  uint64_t;
typedef uint32_t                size_t;


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
