import subprocess, os
from pathlib import Path

os.chdir(Path(__file__).parent.resolve())

gcc = "riscv-none-elf-gcc"
objcopy = "riscv-none-elf-objcopy"
编译参数 = "-march=rv32i -mabi=ilp32 -nostdlib -x assembler-with-cpp".split()
链接脚本 = ["../rust/link.x", "../rust/trap_handler.x"]
链接脚本参数 = [x for ld in 链接脚本 for x in ("-T", ld)]

elf_output = "bootstrap.elf"
编译命令参数 = 编译参数 + ["bootstrap.riscv"] + 链接脚本参数 + ["-o", elf_output]
subprocess.run([gcc] + 编译命令参数, check=True)

flat_output = "bootstrap.bin"
subprocess.run([objcopy, "-O", "binary", elf_output, flat_output], check=True)

with open(flat_output, "rb") as f, open("bootstrap.mem", "w") as out:
    binary_data = f.read()
    for i in range(0, len(binary_data), 4):
        word = binary_data[i : i + 4]
        hex_str = "".join(f"{b:02X}" for b in reversed(word))  # 高位字符在前
        out.write(hex_str + "\n")
