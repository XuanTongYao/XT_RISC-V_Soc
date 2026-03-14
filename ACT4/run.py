import subprocess, os, yaml, re
from pathlib import Path


# Simulation parameters 仿真参数
TRACE_ARGS = "--trace-fst --trace-depth 0"
TOP_TB = "XT_RV32I_Act_tb"
MAX_CYCLES_FACTOR = 3
RAM_WORD_DEPTH = 0x000F_0000

OBJCOPY_EXE = Path("riscv64-unknown-elf-objcopy")
ENTRY = "rvtest_entry_point"

# Required paths 必要路径
RISCV_ARCH_TEST = Path("./riscv-arch-test")
DUT_CONFIG = Path("./xt_rv32i")
HDL = Path("./xt_rv32i_sim/HDL")
VERILATOR_CPP = Path("./xt_rv32i_sim/verilator_cpp")


def main():
    WORKDIR = RISCV_ARCH_TEST / "work"
    CONFIG_FILES = DUT_CONFIG / "test_config.yaml"
    CONFIG = yaml.safe_load(CONFIG_FILES.read_bytes())
    CONFIG_NAME: str = CONFIG["name"]
    OBJDUMP_EXE = Path(CONFIG["objdump_exe"])
    ELFS_DIR = Path(WORKDIR, CONFIG_NAME, "elfs")

    generate_ELFs(RISCV_ARCH_TEST, WORKDIR, CONFIG_FILES)

    # 查询入口点(也作为内存基地址)，所有测试的入口点都相同
    elf_file = next(ELFS_DIR.rglob("*.elf"), None)
    if not elf_file:
        raise FileNotFoundError(
            f"No ELF files in {ELFS_DIR}. 在 {ELFS_DIR} 下没有ELF文件"
        )
    ENTRY_POINT = get_symbols(elf_file, [ENTRY], OBJDUMP_EXE).get(ENTRY)
    if not ENTRY_POINT:
        raise Exception("The symbol {ENTRY} was not found. 没有找到 {ENTRY} 符号")

    exe = build_verilator_simulation_exe(ENTRY_POINT)
    run_test(ENTRY_POINT, ELFS_DIR, OBJDUMP_EXE, exe, MAX_CYCLES_FACTOR)


def generate_ELFs(arch_test_repo: Path, workdir: Path, config_files: Path):
    env = dict(os.environ)  # 拷贝当前环境变量
    env.pop("VIRTUAL_ENV", None)
    env["WORKDIR"] = str(workdir.resolve())
    env["CONFIG_FILES"] = str(config_files.resolve())
    subprocess.run(
        ["make", "--jobs", str(os.cpu_count() or 1)],
        cwd=arch_test_repo,
        env=env,
        check=True,
    )


pattern_package = re.compile(r"^\s*endpackage\s*$")


def is_package(p: Path):
    with p.open("r", encoding="utf-8") as fh:
        for line in fh:
            if pattern_package.match(line):
                return True
    return False


def build_verilator_simulation_exe(ram_base: int):
    sv_files = list(HDL.rglob("*.sv"))
    pkgs = [p for p in sv_files if is_package(p)]
    non_pkgs = [p for p in sv_files if p not in pkgs]
    all_files = [str(file.resolve()) for file in (pkgs + non_pkgs)]

    (VERILATOR_CPP / "rtl.files").write_text("\n".join(all_files), "utf-8")

    cmd = f"verilator {TRACE_ARGS} --top {TOP_TB} -f rtl.files -cc --exe --build sim_main.cpp -GRAM_WORD_DEPTH={RAM_WORD_DEPTH} -GRAM_BASE_ADDR={ram_base}".split()
    subprocess.run(cmd, cwd=VERILATOR_CPP, text=True, check=True)
    return VERILATOR_CPP / "obj_dir" / f"V{TOP_TB}"


# 执行测试
def run_test(
    entry_point: int,
    elfs_dir: Path,
    objdump_exe: Path,
    simulation_exe: Path,
    max_cycles_factor=2,
):
    print("\n\033[1;33m|:------TESTING------:|\033[0m")
    # sig_begin_canary和sig_end_canary才是正确的，begin/end_signature貌似不符合签名
    SYMBOL_NAMES = [".bss", "sig_begin_canary", "sig_end_canary", "tohost", "fromhost"]
    RESULTS_DIR = elfs_dir.parent / "build"
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    WAVES_DIR = Path("./waves")
    WAVES_DIR.mkdir(parents=True, exist_ok=True)
    for elf in elfs_dir.rglob("*.elf"):
        # 不带扩展名的文件名
        stem = elf.stem
        # 去除 elfs_dir 前缀的相对路径（不带扩展名）
        rel_path = elf.relative_to(elfs_dir).with_suffix("")
        # 提取符号
        symbols = get_symbols(elf, SYMBOL_NAMES, objdump_exe)

        hex = elfs_dir.parent / "hex" / rel_path.with_suffix(".hex")
        wave = WAVES_DIR / f"{stem}.fst"
        signature = RESULTS_DIR / rel_path.with_suffix(".sig")
        log = RESULTS_DIR / rel_path.with_suffix(".sig.log")
        dump = RESULTS_DIR / rel_path.with_suffix(".dump")
        signature.parent.mkdir(parents=True, exist_ok=True)
        hex.parent.mkdir(parents=True, exist_ok=True)
        elf_to_hex(elf, hex)
        # 运行仿真
        cmd = [
            str(simulation_exe),
            f"+elf_name={stem}",
            f"+max_cycles={(symbols[".bss"]-entry_point)*max_cycles_factor//4}",
            f"+firmware={hex.resolve()}",
            f"+wave={wave.resolve()}",
            f"+signature={signature.resolve()}",
            f"+log={log.resolve()}",
            f"+dump={dump.resolve()}",
        ]
        cmd += [f"+{name}={addr:08x}" for name, addr in symbols.items()]
        subprocess.run(cmd, text=True, check=True)


def elf_to_hex(elf: Path, hex: Path):
    """转换成十六进制文本"""
    bin = hex.with_suffix(".bin")
    subprocess.run([str(OBJCOPY_EXE), "-O", "binary", str(elf), str(bin)], check=True)

    with open(bin, "rb") as f_in, open(hex, "w") as f_out:
        data = f_in.read()
        for i in range(0, len(data), 4):
            val = int.from_bytes(data[i : i + 4], "little")
            f_out.write(f"{val:08x}\n")


def get_symbols(elf: Path, symbol_names: list[str], objdump_exe: Path):
    """提取 ELF 中的指定符号地址"""
    result = subprocess.run(
        [str(objdump_exe), "-t", str(elf)], capture_output=True, text=True, check=True
    )
    symbols: dict[str, int] = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) > 2:
            addr, name = parts[0], parts[-1]
            if name in symbol_names:
                symbols[name] = int(addr, 16)
    return symbols


if __name__ == "__main__":
    main()
