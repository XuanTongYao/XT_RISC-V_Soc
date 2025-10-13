#ifndef sim_mem_H
#define sim_mem_H
#include <cstdint>
#include <vector>
#include <sstream>
#include <stdexcept>

enum WriteWidth : uint8_t {
    BYTE = 0b00,
    HALFWORD = 0b01,
    WORD = 0b10,
    DWORD = 0b11,
};

class sim_mem
{
private:
    enum Align : uint8_t {
        HALFWORD = 0b01,
        WORD = 0b10,
        DWORD = 0b11,
    };
    std::vector<uint8_t> mem;
    uint64_t addr_align(const uint64_t raw_addr, const Align align);
    uint64_t read_data(uint64_t addr, const size_t len = 4);
    template<typename T>
    void write_data(uint64_t addr, T data);
public:
    std::vector<uint8_t>& get_mem() { return mem; }
    sim_mem(const uint64_t byte_depth) :mem(byte_depth) {};
    void wirte(const WriteWidth width, const  uint64_t data, const  uint64_t addr);
    uint64_t read(const uint64_t addr);
    uint32_t read_inst(const uint64_t addr);
    uint16_t read_cinst(const uint64_t addr);
};

template<typename T>
inline void sim_mem::write_data(uint64_t addr, T data) {
    if (addr + sizeof(data) >= mem.size()) {
        std::ostringstream oss;
        oss << "try write invaild address: " << addr << " len: " << sizeof(data);
        throw std::runtime_error(oss.str());
    }
    for (size_t i = 0; i < sizeof(data); i++, addr++) {
        uint8_t byte = data & 0xFF;
        mem.at(addr) = byte;
        data >>= 8;
    }
}

inline uint64_t sim_mem::addr_align(const uint64_t raw_addr, const Align align) {
    if (align == Align::DWORD) return raw_addr & ~uint64_t(0b111);
    if (align == Align::WORD) return raw_addr & ~uint64_t(0b011);
    if (align == Align::HALFWORD) return raw_addr & ~uint64_t(0b001);
    return raw_addr;
}

inline uint64_t sim_mem::read_data(uint64_t addr, const size_t len) {
    if (addr + len >= mem.size()) {
        std::ostringstream oss;
        oss << "try read invaild address: " << addr << " len: " << len;
        throw std::runtime_error(oss.str());
    }
    uint64_t ret = 0;
    for (size_t i = 0; i < len; i++, addr++) {
        ret |= uint64_t(mem.at(addr)) << (i * 8);
    }
    return ret;
}

inline void sim_mem::wirte(const WriteWidth width, const uint64_t data, const uint64_t addr) {
    if (width == WriteWidth::DWORD) {
        write_data(addr, static_cast<uint64_t>(data));
    } else if (width == WriteWidth::WORD) {
        write_data(addr, static_cast<uint32_t>(data));
    } else if (width == WriteWidth::HALFWORD) {
        write_data(addr, static_cast<uint16_t>(data));
    } else if (width == WriteWidth::BYTE) {
        write_data(addr, static_cast<uint8_t>(data));
    }
}

inline uint64_t sim_mem::read(const uint64_t addr) {
    return read_data(addr, 8);
}

inline uint32_t sim_mem::read_inst(const uint64_t addr) {
    auto inst_addr = addr_align(addr, Align::HALFWORD);
    return static_cast<uint32_t>(read_data(inst_addr, 4));

}


inline uint16_t sim_mem::read_cinst(const uint64_t addr) {
    auto inst_addr = addr_align(addr, Align::HALFWORD);
    return static_cast<uint16_t>(read_data(inst_addr, 2));
}



#endif
