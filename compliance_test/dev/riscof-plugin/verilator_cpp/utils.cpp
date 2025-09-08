#include "utils.h"
#include "verilated.h"
#include <iostream>
#include <fstream>
#include <iomanip>


bool plusarg(const char* prefixp, std::string& out, bool err_hint) {
    auto faild_hint = err_hint ? "ERROR: " : "INFO: ";
    const char* p = Verilated::commandArgsPlusMatch(prefixp);
    if (p != nullptr) {
        // 返回的是以 patt 开头的 C 字符串
        std::string s(p);
        std::string patt = std::string("+") + prefixp + "=";
        if (s.size() > patt.size()) {
            out = s.substr(patt.size());
            return true;
        }
    }
    std::cout << faild_hint << prefixp << " $plusarg not found!\n";
    return false;
}
bool plusarg(const std::string& prefixp, std::string& out, bool err_hint) {
    return plusarg(prefixp.c_str(), out, err_hint);
}

void dump_bin(const std::vector<uint8_t>& mem, std::ofstream& ofs, const size_t start, const size_t len) {
    if (start >= mem.size() || start + len > mem.size()) {
        return;
    }

    ofs.write(reinterpret_cast<const char*>(mem.data() + start), len);
    ofs.close();
}

void dump_hex(const std::vector<uint8_t>& mem, std::ofstream& ofs, const size_t line_bytes, const size_t start, const size_t len) {
    ofs << std::hex << std::setfill('0');

    uint64_t addr = start;
    size_t done = 0;
    while (done < len) {
        uint64_t high_addr = addr + line_bytes - 1;
        for (size_t i = 0; i < line_bytes; high_addr--, i++) {
            auto byte_data = static_cast<uint32_t>(mem.at(high_addr));
            ofs << std::setw(2) << byte_data;
        }
        addr += line_bytes;
        done += line_bytes;
        ofs << "\n";
    }
}


VerilatedFstC* FstC_logger = nullptr;
std::ofstream* file_logger = nullptr;


void register_FstC_logger(VerilatedFstC* logger) {
    FstC_logger = logger;
}

void register_logger(std::ofstream* logger) {
    file_logger = logger;
}

void safe_exit() {
    if (FstC_logger) FstC_logger->close();
    if (file_logger) file_logger->close();
    std::exit(1);
}

