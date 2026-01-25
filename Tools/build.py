import subprocess, os
from pathlib import Path

# 改到项目目录
os.chdir(Path(__file__).parent.parent.absolute())
import inc

gcc = "riscv64-unknown-elf-gcc"
objcopy = "riscv64-unknown-elf-objcopy"
gcc = "riscv-none-elf-gcc"
objcopy = "riscv-none-elf-objcopy"

架构 = "-march=rv32i_zicsr -mabi=ilp32"
库参数 = "-nostdlib"
其他参数 = "-fstrict-volatile-bitfields"
优化等级 = "-Os"
其他优化 = "-flto"
启动文件 = ["./C_lib/Startup/start.s"]
# 启动文件 = ["./C_lib/Startup/simple_start.s"]
链接脚本 = "./C_lib/Startup/link.ld"


def entry():
    main_file, main_file_name = select_main_file()
    output_name = main_file_name.removesuffix(".c") + 优化等级
    build(main_file, output_name)


def select_main_file():
    print("程序:")
    for i, file in enumerate(inc.MAIN_FILES):
        if i == len(inc.USER_FILES):
            print("功能验证:")
        print(f"{i}->{file}")
    sel = input("选择主文件")
    if sel.isdecimal():
        sel_index = int(sel)
    else:
        sel_index = 0
    main_file = inc.MAIN_FILES_FULL[sel_index]
    main_file_name = Path(main_file).name
    if sel_index >= len(inc.USER_FILES):
        main_file_name = os.path.join("Verification", main_file_name)
    return main_file, main_file_name


def build(main_file: str, output_name: str):
    elf_output = os.path.join(inc.ELF_DIR, output_name) + ".elf"
    # 编译链接生成ELF
    编译参数 = f"{架构} {库参数} {其他参数} {优化等级} {其他优化}".split()
    源文件 = 启动文件 + [main_file] + inc.COMPILE_LIST
    链接脚本参数 = f"-T {链接脚本}".split()
    输出参数 = f"-o {elf_output}".split()
    编译命令参数 = 编译参数 + inc.INCLUDE_PARAMS + 源文件 + 链接脚本参数 + 输出参数
    subprocess.run([gcc] + 编译命令参数, check=True)

    # 生成纯二进制文件
    flat_output = os.path.join(inc.BIN_DIR, output_name) + ".bin"
    subprocess.run([objcopy, "-O", "binary", elf_output, flat_output], check=True)

    # 生成16进制文本文件
    txt_output = os.path.join(inc.TXT_DIR, output_name) + ".mem"
    with open(flat_output, "rb") as f:
        binary_data = f.read()
        with open(txt_output, "w") as out:
            for i in range(0, len(binary_data), 4):
                word = binary_data[i : i + 4]
                hex_str = "".join(f"{b:02X}" for b in reversed(word))  # 高位字符在前
                out.write(hex_str + "\n")

    align_to_page(flat_output, output_name)


def align_to_page(flat_output: str, output_name: str):
    page_out = os.path.join(inc.BIN_PAGE_DIR, output_name) + ".bin"
    with open(flat_output, "rb") as f:
        binary_data = f.read()
        with open(page_out, "wb") as out:
            out.write(binary_data)
            if len(binary_data) % 16 != 0:
                padding = 16 - (len(binary_data) % 16)
                for _ in range(padding):
                    out.write(b"\x00")
    # page_txt_output = os.path.join(inc.TXT_DIR, output_name) + "page.mem"
    # with open(page_out, "rb") as f:
    #     binary_data = f.read()
    #     with open(page_txt_output, "w") as out:
    #         for i in range(0, len(binary_data), 16):
    #             page = binary_data[i : i + 16]
    #             hex_str = "".join(f"{b:02X}" for b in reversed(page))  # 高位字符在前
    #             out.write(hex_str + "\n")


if __name__ == "__main__":
    entry()
