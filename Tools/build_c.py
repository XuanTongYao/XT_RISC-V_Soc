import subprocess, os
from pathlib import Path

# 改到项目目录
os.chdir(Path(__file__).parent.parent.resolve())
import inc

# 旧编译器（更小体积）
gcc = "riscv64-unknown-elf-gcc"
objcopy = "riscv64-unknown-elf-objcopy"
架构 = "-march=rv32i -mabi=ilp32"

# 新编译器（更加成熟）
gcc = "riscv-none-elf-gcc"
objcopy = "riscv-none-elf-objcopy"
架构 = "-march=rv32i_zicsr -mabi=ilp32"

库参数 = "-nostdlib"
其他参数 = "-fstrict-volatile-bitfields"
优化等级 = "-Os"
其他优化 = "-flto"
启动文件 = ["C_lib/Startup/start.s"]
# 启动文件 = ["C_lib/Startup/simple_start.s"]
链接脚本 = "C_lib/Startup/link.ld"


def entry():
    main_file = select_main_file()
    output = Path(main_file.with_stem(main_file.stem + 优化等级).name)
    if main_file.parent.stem == "Verification":
        output = Path("Verification", output)
    build(main_file, output)


def select_main_file():
    print("程序:")
    v = True
    for i, file in enumerate(inc.MAIN_FILES):
        if v and file.parent.stem == "Verification":
            print("功能验证:")
            v = False
        print(f"{i} -> {file.name}")
    sel = input("选择主文件")
    sel_index = int(sel) if sel.isdecimal() else 0
    main_file = inc.MAIN_FILES[sel_index]
    return main_file


def build(main_file: str | Path, output: Path):
    elf_output = inc.ELF_DIR / output.with_suffix(".elf")
    # 编译链接生成ELF
    编译参数 = f"{架构} {库参数} {其他参数} {优化等级} {其他优化}".split()
    源文件 = 启动文件 + [str(main_file)] + inc.COMPILE_LIST
    链接脚本参数 = f"-T {链接脚本}".split()
    输出参数 = f"-o {elf_output}".split()
    编译命令参数 = 编译参数 + inc.INCLUDE_PARAMS + 源文件 + 链接脚本参数 + 输出参数
    subprocess.run([gcc] + 编译命令参数, check=True)

    # 生成纯二进制文件
    flat_output = str(inc.BIN_DIR / output.with_suffix(".bin"))
    subprocess.run([objcopy, "-O", "binary", str(elf_output), flat_output], check=True)

    # 生成16进制文本文件
    txt_output = inc.TXT_DIR / output.with_suffix(".mem")
    with open(flat_output, "rb") as f, open(txt_output, "w") as out:
        binary_data = f.read()
        for i in range(0, len(binary_data), 4):
            word = binary_data[i : i + 4]
            hex_str = "".join(f"{b:02X}" for b in reversed(word))  # 高位字符在前
            out.write(hex_str + "\n")

    align_to_page(flat_output, output)


def align_to_page(flat_output: str | Path, output: Path):
    page_out = inc.BIN_PAGE_DIR / output.with_suffix(".bin")
    with open(flat_output, "rb") as f, open(page_out, "wb") as out:
        binary_data = f.read()
        out.write(binary_data)
        padding = (16 - (len(binary_data) % 16)) % 16
        for _ in range(padding):
            out.write(b"\x00")
    # page_txt_output = inc.TXT_DIR / output.with_suffix(".page.mem")
    # with open(page_out, "rb") as f, open(page_txt_output, "w") as out:
    #     binary_data = f.read()
    #     for i in range(0, len(binary_data), 16):
    #         page = binary_data[i : i + 16]
    #         hex_str = "".join(f"{b:02X}" for b in reversed(page))  # 高位字符在前
    #         out.write(hex_str + "\n")


if __name__ == "__main__":
    entry()
