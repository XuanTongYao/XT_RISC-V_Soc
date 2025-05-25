#include "XT_RISC_V_Base.h"



//----------外设定义-----------//
//TODO:外设寄存器需要进行32位改造，每次只传输1字节速度太慢
#include "uart.h"
#include "wishbone.h"
#include "xt_lb.h"

