from pathlib import Path

# 用户自定义程序
user_paths = ["tests"]


# 包含相关
include_paths = [
    "C_lib/XT_RISC_V",
]
firmware_paths = [
    "firmware_lib",
]
COMPILE_LIST = []
for p in include_paths:
    COMPILE_LIST.extend([str(f) for f in Path(p).rglob("*.c")])


# 创建输出文件夹
OUTPUT_DIR = "build"
output_types = ["ELFs", "FlatBinary", "FlatBinaryTxt", "FlatPage"]
output_dirs = [Path(OUTPUT_DIR, i) for i in output_types]

ELF_DIR = output_dirs[0]
BIN_DIR = output_dirs[1]
TXT_DIR = output_dirs[2]
BIN_PAGE_DIR = output_dirs[3]
for dir in output_dirs:
    (dir / "Verification").mkdir(parents=True, exist_ok=True)


MAIN_FILES: list[Path] = []
for p in user_paths:
    MAIN_FILES.extend(Path(p).rglob("*.c"))

INCLUDE_PARAMS: list[str] = []
for p in include_paths:
    INCLUDE_PARAMS.append("-I")
    INCLUDE_PARAMS.append(p)
    for i in Path(p).rglob("*"):
        if i.is_dir():
            INCLUDE_PARAMS.append("-I")
            INCLUDE_PARAMS.append(str(i))
for p in firmware_paths:
    INCLUDE_PARAMS.append("-I")
    INCLUDE_PARAMS.append(p)
