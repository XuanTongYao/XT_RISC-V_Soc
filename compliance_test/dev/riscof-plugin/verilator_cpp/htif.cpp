#include "htif.h"
#include "utils.h"
#include <iostream>
#include <fstream>
#include <iomanip>


void Htif::parse_htif_plusargs() {
    std::string val;

    std::cout <<
        "+--------+\n" <<
        "HTIF parse $plusargs\n" <<
        "+--------+" << std::endl;

    for (size_t i = 0; i < symbols_ptr.size(); i++) {
        auto prefixp = asm_symbols.at(i);
        auto arg_ptr = symbols_ptr.at(i);
        if (plusarg(prefixp, val, true)) {
            *arg_ptr = std::stoull(val, nullptr, 16);
            // 忽略rvtest_entry_point自身
            if (std::string("rvtest_entry_point") != prefixp) *arg_ptr -= rvtest_entry_point;
            std::cout << prefixp << " = 0x"
                << std::setw(8) << std::setfill('0') << std::hex
                << *arg_ptr << std::dec << std::endl;
        } else {
            safe_exit();
        }
    }

    if (!plusarg("signature", signature, true)) {
        safe_exit();
    }

    std::cout << "=--------=" << std::endl;
}

Htif::Htif() {
    parse_htif_plusargs();
}

void Htif::dump(const std::vector<uint8_t>& mem) {
    std::ofstream ofs(signature);
    if (!ofs.is_open()) {
        std::cerr << "ERROR: cannot open signature file " << signature << "\n";
        safe_exit();
    }

    dump_hex(mem, ofs, 4, begin_signature, end_signature - begin_signature);

    // ofs << std::hex << std::setfill('0');
    // for (uint64_t addr = begin_signature; addr < end_signature; addr += 4) {
    //     // 小端序写出，每行 32bit
    //     uint32_t word_data = 0;
    //     uint64_t tmp_addr = addr;
    //     for (size_t i = 0; i < 4; i++, tmp_addr++) {
    //         word_data |= ((uint32_t)mem.at(tmp_addr)) << (i * 8);
    //     }
    //     ofs << std::setw(8) << word_data << "\n";
    // }

    ofs.close();
}

uint64_t Htif::get_inst_num() {
    return begin_signature / 4;
}

void Htif::try_halt(const uint64_t addr, const uint64_t data) {
    if (addr == tohost) {
        htif_halt = data;
    }
}

bool Htif::check_halt() {
    return htif_halt != 0;
}

void Htif::finish(const std::vector<uint8_t>& dump_mem) {
    dump(dump_mem);
    std::cout << "HTIF: Saving signature file with data from 0x"
        << std::hex << std::setw(8) << std::setfill('0') << begin_signature
        << " to 0x"
        << std::hex << std::setw(8) << std::setfill('0') << end_signature
        << ": " << signature << std::endl;
}

