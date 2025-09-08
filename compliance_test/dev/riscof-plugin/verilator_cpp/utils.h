#include <string>
#include <vector>
#include <cstdint>
#include <limits>
#include <fstream>
#include "verilated_fst_c.h"

bool plusarg(const char* prefixp, std::string& out, bool err_hint = false);
bool plusarg(const std::string& prefixp, std::string& out, bool err_hint = false);
void dump_bin(const std::vector<uint8_t>& mem, std::ofstream& ofs, const size_t start = 0, const size_t len = std::numeric_limits<size_t>::max());
void dump_hex(const std::vector<uint8_t>& mem, std::ofstream& ofs, const size_t line_bytes = 4, const size_t start = 0, const size_t len = std::numeric_limits<size_t>::max());

void register_FstC_logger(VerilatedFstC* logger);
void register_logger(std::ofstream* logger);
void safe_exit();

