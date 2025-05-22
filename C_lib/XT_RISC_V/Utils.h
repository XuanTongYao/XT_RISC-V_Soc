#ifndef Utils_H
#define Utils_H

/*
这个文件包含了很多实用的工具函数
1. 简单位操作
    - 获取位 GetBit(X,1); // 获取X数据的第1位
    - 设置位 SetBit(X,1); // 设置X数据的第1位 为 1
    - 重置位 ResetBit(X,0); // 设置X数据的第0位 为 0
    - ...
2. 简单数据处理
    - MAX(a,b))
*/


//----------便捷位操作----------//
// 位掩码
#define BITX_MASK(X) (1U<<(X))
// 低位掩码
#define BIT_LX_MASK(X) (BITX_MASK(X) - 1U)
// 高位掩码(N bit对齐)
#define BITN_HX_MASK(X,N) (BIT_LX_MASK(X) << ((N)-(X)))

#define SetBit(Data,Bit) (Data) |= BITX_MASK(Bit)// 把数据某一位设为1
#define ResetBit(Data,Bit) (Data) &= ~BITX_MASK(Bit)// 把数据某一位设为0
#define GetBit(Data,Bit) (((Data) & BITX_MASK(Bit)) == BITX_MASK(Bit)) // 获取数据某一位
#define GetBitLow(Data,Len) ((Data) & BIT_LX_MASK(Len)) // 获取数据低几位
#define GetBitHigh(Data,Len,N) (((Data) & BITN_HX_MASK(Len,N)) >> ((N)-(X))) // 获取数据高几位并右对齐，需要指定数据总长度N
// High - 高位  Low - 低位  左右闭区间 Low不能为0
#define GetBits(Data,High,Low) (BIT_LX_MASK(High) & ~BIT_LX_MASK((Low)-1U))
#define GetByteN(Data,N) (((Data) & (0xFF << (N*8)))>>(N*8))

// 各位与
#define ReductionAnd(Data) (~Data==0)
// 各位或
#define ReductionOr(Data) (Data!=0)



//----------简单数据处理----------//
#define M_PI 3.1415926f

// 限制值
#define Clamp(x, min, max) (((x) < (min)) ? (min) : (((x) > (max)) ? (max) : (x)))
// 两者最小值
#define Min(a, b) (((a) < (b)) ? (a) : (b))
// 两者最大值
#define Max(a, b) (((a) > (b)) ? (a) : (b))
// 两者距离(差值绝对值)
#define Distance(a, b) (((a) > (b)) ? ((a)-(b)) : ((b)-(a)))
// 绝对值
#define Abs(x) (((x) > 0) ? (x) : (-(x)))
// // 弧度转角度
// #define Rad2Deg(radian) ((radian)*(180.0f/3.1415926f))
// // 角度转弧度
// #define Deg2Rad(degree) ((degree)*(3.1415926f/180.0f))

#endif

