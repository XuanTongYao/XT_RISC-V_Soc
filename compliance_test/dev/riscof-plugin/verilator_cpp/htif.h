#include <cstdint>
#include <string>
#include <vector>
#include <array>

class Htif
{
private:
    int htif_halt = 0;
    uint64_t rvtest_entry_point;
    uint64_t begin_signature;
    uint64_t end_signature;
    uint64_t tohost;
    uint64_t fromhost;
    std::string signature;
    static constexpr std::array<const char*, 5> asm_symbols = {
         "rvtest_entry_point","begin_signature","end_signature","tohost","fromhost"
    };
    std::array<uint64_t*, 5> symbols_ptr = {
         &rvtest_entry_point,&begin_signature,&end_signature,&tohost,&fromhost
    };
    void parse_htif_plusargs();
    void dump(const std::vector<uint8_t>& mem);
public:
    Htif(/* args */);
    // 粗略获取指令数量
    uint64_t get_inst_num();
    void try_halt(const uint64_t addr, const uint64_t data);
    bool check_halt();
    void finish(const std::vector<uint8_t>& dump_mem);
};

