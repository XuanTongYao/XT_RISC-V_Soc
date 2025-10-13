#include "VRISC_V_Core.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "sim_mem.hpp"
#include "htif.h"
#include "utils.h"
#include <iostream>
#include <sstream>
#include <fstream>

#define EN_HTIF
#define EN_LOG false

VRISC_V_Core* top;
sim_mem* mem;
#ifdef EN_HTIF
Htif* htif;
#endif
size_t loop_cnt;
VerilatedFstC* tfp;

auto warpped_eval = []() {
#if EN_LOG
    Verilated::timeInc(1);
#endif
    top->eval();
#if EN_LOG
    tfp->dump(Verilated::time());
#endif
    };

static void reset() {
    // 初始化
    top->clk = 1;
    top->rst_sync = 1;
    for (size_t i = 0; i < 4; i++) {
        top->clk = 0;
        warpped_eval();
        top->clk = 1;
        warpped_eval();
    }
    top->rst_sync = 0;
}

static void test(size_t timeout = 10000) {
    std::cout << "Start test" << std::endl;
    top->instruction = mem->read_inst(top->instruction_addr);
    try {
        for (loop_cnt = 0; loop_cnt < timeout; loop_cnt++) {
            top->clk = 0;
            warpped_eval();
            top->clk = 1;
            auto last_inst_addr = top->instruction_addr;
            warpped_eval();
            top->instruction = mem->read_inst(last_inst_addr);

#ifdef EN_HTIF
            if (htif->check_halt()) {
                std::cout << "HTIF: HALT" << std::endl;
                htif->finish(mem->get_mem());
                return;
            }
#endif
            if (top->access_ram_read) {
                top->access_ram_rdata = mem->read(top->access_ram_raddr);
            } else if (top->access_ram_write) {
                mem->wirte((WriteWidth)top->access_ram_write_width, top->access_ram_wdata, top->access_ram_waddr);
#ifdef EN_HTIF
                htif->try_halt(top->access_ram_waddr, top->access_ram_wdata);
#endif
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << "catch an exception on " << loop_cnt << " loop_cnt\n"
            << e.what() << std::endl;
        throw std::runtime_error("break");
    }

#ifdef EN_HTIF
    std::cout << "HTIF: TIMEOUT" << std::endl;
    htif->finish(mem->get_mem());
#endif
}

static void finish() {
    for (size_t i = 0; i < 4; i++) {
        top->clk = !top->clk;
        warpped_eval();
        top->clk = !top->clk;
        warpped_eval();
    }
}

// 内存相关
constexpr size_t SIGNATURE_SIZE = 0x00008000;
void read_test_bin(std::ifstream& fwifs, size_t fw_size, std::vector<uint8_t>& mem) {
    fwifs.seekg(0, std::ios::beg);

    // 读取文件到 mem
    if (!fwifs.read(reinterpret_cast<char*>(mem.data()), fw_size)) {
        std::cerr << "ERROR: Failed to read firmware\n";
        safe_exit();
    }

    std::cout << "Read " << fw_size << "B from firmware" << std::endl;
}


int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(EN_LOG);
    // 标准输出重定向
    std::ofstream logger("sim.log");
    register_logger(&logger);
    auto old_stream = std::cout.rdbuf(logger.rdbuf());

    // 检查测试指令
    std::string fw;
    std::ifstream fwifs;
    uint64_t fw_size;
    if (!plusarg("firmware", fw, true)) safe_exit();
    fwifs.open(fw, std::ios::binary | std::ios::ate);
    if (!fwifs) {
        std::cerr << "ERROR: Failed to open firmware file: " << fw << "\n";
        safe_exit();
    }
    fw_size = fwifs.tellg();

    // 初始化模块
    top = new VRISC_V_Core();
    mem = new sim_mem(SIGNATURE_SIZE + fw_size);
    std::cout << "Loading file into memory: " << fw << std::endl;
    read_test_bin(fwifs, fw_size, mem->get_mem());// 加载测试指令
    htif = new Htif();

    // 信号跟踪
#if EN_LOG
    auto levels = 0;
    std::string tracelevels;
    if (plusarg("tracelevels", tracelevels))
        levels = std::stoi(tracelevels);
    tfp = new VerilatedFstC();
    top->trace(tfp, levels);
    tfp->open("simwave.fst");
    register_FstC_logger(tfp);
#endif

    // 复位
    reset();

    // 测试
    std::string timeout_str;
    size_t timeout = htif->get_inst_num() * 2;
    if (plusarg("timeout", timeout_str)) {
        timeout = std::stoul(timeout_str);
        std::cout << "Set timeout=" << std::dec << timeout << std::endl;
    }
    test(timeout);
    // 结束
    finish();
    std::cout << "FINAL\n" << "TIME: cnt = " << std::dec << loop_cnt << std::endl;
    // std::ofstream ofs("test_dump_bin", std::ios::binary);
    // dump_bin(mem->get_mem(), ofs, 0, 80);
#if EN_LOG
    tfp->close();
    delete tfp;
#endif
    std::cout.rdbuf(old_stream);
    logger.close();
    delete top;
    delete mem;
    delete htif;
    return 0;
}
