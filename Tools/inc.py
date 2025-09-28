import os
from pathlib import Path
import glob

# 用户自定义程序
user_paths = ["./tests"]
USER_FILES = []
USER_FILES_FULL = []

for path in user_paths:
    c_files = glob.glob(os.path.join(path, "*.c"))
    USER_FILES.extend([Path(f).name for f in c_files])
    USER_FILES_FULL.extend([str(Path(f).resolve()) for f in c_files])

verify_path = "./tests/Verification"
c_files = glob.glob(os.path.join(verify_path, "*.c"))
verify_files = [Path(f).name for f in c_files]
verify_files_full = [str(Path(f).resolve()) for f in c_files]


# 包含相关
include_paths = [
    "./C_lib/XT_RISC_V",
    "./C_lib/XT_RISC_V/Peripherals",
    "./C_lib/XT_RISC_V/WISHBONE",
    "./C_lib/XT_RISC_V/XT_LB",
]

COMPILE_LIST = []
for path in include_paths:
    c_files = glob.glob(os.path.join(path, "*.c"))
    COMPILE_LIST.extend([str(Path(f).resolve()) for f in c_files])


# 创建输出文件夹
OUTPUT_DIR = "./build"
output_types = ["ELFs", "FlatBinary", "FlatBinaryTxt", "FlatPage"]
output_dirs = [os.path.join(OUTPUT_DIR, i) for i in output_types]
ELF_DIR = output_dirs[0]
BIN_DIR = output_dirs[1]
TXT_DIR = output_dirs[2]
BIN_PAGE_DIR = output_dirs[3]
folder_paths = [OUTPUT_DIR] + output_dirs
for dir in output_dirs:
    folder_paths.append(os.path.join(dir, "Verification"))

for folder in folder_paths:
    Path(folder).mkdir(parents=True, exist_ok=True)


MAIN_FILES: list[str] = USER_FILES + verify_files
MAIN_FILES_FULL: list[str] = USER_FILES_FULL + verify_files_full
INCLUDE_PARAMS: list[str] = []
for path in include_paths:
    INCLUDE_PARAMS.append("-I")
    INCLUDE_PARAMS.append(path)
