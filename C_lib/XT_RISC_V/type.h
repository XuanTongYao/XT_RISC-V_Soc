#ifndef TYPE_H
#define TYPE_H
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// 指示函数为中断处理函数，以便编译器正确保存并转移上下文
#define IRQ __attribute__((interrupt)) void

typedef volatile uint8_t* byte_reg_ptr;
typedef volatile uint16_t* half_reg_ptr;
typedef volatile uint32_t* word_reg_ptr;
typedef volatile uint64_t* dword_reg_ptr;
typedef const byte_reg_ptr      ro_byte_reg_ptr;
typedef const half_reg_ptr      ro_half_reg_ptr;
typedef const word_reg_ptr      ro_word_reg_ptr;
typedef const dword_reg_ptr     ro_dword_reg_ptr;
typedef byte_reg_ptr            wo_byte_reg_ptr;
typedef half_reg_ptr            wo_half_reg_ptr;
typedef word_reg_ptr            wo_word_reg_ptr;
typedef dword_reg_ptr           wo_dword_reg_ptr;

#endif
