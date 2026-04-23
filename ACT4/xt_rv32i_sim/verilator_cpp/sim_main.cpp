#include "VXT_RV32I_Act_tb.h"
#include "verilated.h"
#include <iostream>

VXT_RV32I_Act_tb* top;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // 初始化模块
    top = new VXT_RV32I_Act_tb();

    // 复位
    Verilated::timeInc(1);
    top->clk = 0;
    top->rst = 1;
    top->eval();
    for (size_t i = 0; i < 4; i++) {
        Verilated::timeInc(1);
        top->clk = !top->clk;
        top->eval();
    }
    top->rst = 0;
    // 测试
    while (!Verilated::gotFinish()) {
        Verilated::timeInc(1);
        top->clk = !top->clk;
        top->eval();
    }

    delete top;
    return 0;
}
