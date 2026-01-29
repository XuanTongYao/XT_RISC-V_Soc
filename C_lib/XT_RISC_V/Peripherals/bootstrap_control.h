#ifndef BOOTSTRAP_CONTROL_H
#define BOOTSTRAP_CONTROL_H
#include "type.h"
#include "addr_define.h"

// 读取数据表示启动时状态
#define DOWNLOAD_MODE 0x01
// 向DEBUG_REG写入数据以切换模式
#define INTO_NORMAL_MODE 0xF0
#define DEBUG_REG ((byte_reg_ptr)(DEBUG_BASE))

// 使用自动增地址的硬件实现字符串输出
#define PRELOAD_STR_INIT_ADDR_REG ((wo_byte_reg_ptr)(DEBUG_BASE+4))
#define PRELOAD_STR_AUTO_INC_REG ((ro_byte_reg_ptr)(DEBUG_BASE+8))

#endif
