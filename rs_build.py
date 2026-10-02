import os
import subprocess
import sys
from argparse import ArgumentParser
from collections.abc import Sequence
from contextlib import suppress
from json import loads
from pathlib import Path
from shutil import copy2

# 切换到项目目录
os.chdir(Path(__file__).parent.resolve())

# ===================== 默认配置 ====================
TARGET_TRIPLE = "riscv32i-unknown-none-elf"  # target 要与config.toml里的相同
PAGE_ALIGN = 16  # 页的对齐字节数
PADDING_BYTE = b"\x00"  # 对齐填充数据
# ===================================================


def main():
    args = parse_args()
    with suppress(KeyboardInterrupt):
        # print(args)
        cmds = wizard(args)
        cargo(**cmds)
        sys.exit()
    print("被中断退出")


# 定义有效的命令、模式和种类
VALID_CMDS = ("objdump", "objcopy", "build", "run")
VALID_KIND = ("bin", "example", "test", "bench")

RAM_SECTIONS = (".text", ".rodata", ".data", ".sdata", ".bss")
DEFAULT_TOOL_ARGS = {
    "objcopy": ["-O", "binary"],
    "objdump": [
        "-d",
        "--print-imm-hex",
        "-M",
        "no-aliases",
        "--demangle",
    ]
    + [x for s in RAM_SECTIONS for x in ("-j", s)],
}


def cargo(
    cmd: str,
    release: bool,
    kind: str,
    name: str,
    features=None,
    tool_args=None,
    extra=None,
):

    mode = "release" if release else "debug"
    argv = ["cargo", cmd]
    if release:
        argv.append("--release")
    argv += [f"--{kind}", name]
    if features:
        argv += ["-F", features]

    trailing = list(
        tool_args if tool_args is not None else DEFAULT_TOOL_ARGS.get(cmd, [])
    )
    trailing += list(extra or [])

    bin_path = Path(f"rust_{mode}/bin/{name}.bin")
    if cmd == "objcopy":
        bin_path.parent.mkdir(parents=True, exist_ok=True)
        trailing.append(str(bin_path))
    if trailing:
        argv += ["--", *trailing]

    subprocess.run(argv, check=True)

    elf = artifact_path(kind, mode, name)
    if elf is not None:
        dest = Path(f"rust_{mode}/elfs/{name}.elf")
        dest.parent.mkdir(parents=True, exist_ok=True)
        copy2(elf, dest)
    else:
        print(f"警告: 未找到 ELF（{kind} {name}）")

    if cmd == "objcopy":
        pad_to_page(bin_path)


def artifact_path(kind, mode, name):
    base: Path = Path("target") / TARGET_TRIPLE / mode
    if kind == "bin":
        path: Path = base / name
        return path if path.is_file() else None
    if kind == "example":
        path: Path = base / "examples" / name
        return path if path.is_file() else None
    # test/bench 产物在 deps/ 下，文件名带 hash，且没有扩展名
    matches = [
        p for p in (base / "deps").glob(f"{name}-*") if p.is_file() and not p.suffix
    ]
    return max(matches, key=lambda p: p.stat().st_mtime) if matches else None


def wizard(args: dict):

    no_target = not any(args.get(key) for key in VALID_KIND)

    pts = [p for p in get_targets() if p]
    if not pts and no_target:
        print("当前无编译目标")
        sys.exit(1)

    cmd = args["cmd"] or select_item(VALID_CMDS, "\n选择执行命令:")

    if no_target:
        kinds = list(dict.fromkeys(key for p in pts for key in p.targets))
        kind: str = select_item(kinds, "\n选择种类:")
        targets = []
        for pt in pts:
            if t := pt.targets.get(kind):
                targets.extend(t)
        args[kind] = select_item(targets, "\n选择目标:")

    kind: str = next(k for k in VALID_KIND if args.get(k))
    return {
        "cmd": cmd,
        "release": args["release"],
        "kind": kind,
        "name": args[kind],
        "features": args["features"] or None,
        "tool_args": args["passed_args"] or None,
        "extra": args["additional"] or None,
    }


def parse_args():
    """解析命令行参数"""

    parser = ArgumentParser(description="rust构建向导", prefix_chars="-+")

    parser.add_argument("cmd", nargs="?")
    parser.add_argument("-r", "--release", action="store_true")
    target_group = parser.add_mutually_exclusive_group()
    for i in VALID_KIND:
        target_group.add_argument(f"--{i}")

    parser.add_argument("-F", "--features", type=str)
    parser.add_argument("+", action="append", dest="additional", type=str)
    parser.add_argument("passed_args", nargs="*", type=str)

    args, unknown = parser.parse_known_intermixed_args()

    if args.cmd is not None and args.cmd not in VALID_CMDS:
        args.passed_args.append(args.cmd)
        args.cmd = None
    args.passed_args.extend(unknown)
    return vars(args)


def select_num(options: Sequence, prompt: object = ""):
    if len(options) == 1:
        return 0
    print(prompt)
    print("\n".join(f"{i}\t->\t{t}" for i, t in enumerate(options)))
    while True:
        n = input("> ")
        if n.isdigit() and int(n) < len(options):
            return int(n)
        print("请重新输入")


def select_item(options: Sequence, prompt: object = ""):
    return options[select_num(options, prompt)]


def get_targets() -> list["PackageTargets"]:
    ret = subprocess.run(
        ["cargo", "metadata", "--no-deps", "-q"],
        check=True,
        capture_output=True,
        encoding="utf-8",
    )
    packages: dict = loads(ret.stdout)["packages"]

    return [
        PackageTargets(p["name"], [(t["kind"][0], t["name"]) for t in p["targets"]])
        for p in packages
    ]


class PackageTargets:
    def __init__(self, name, targets) -> None:
        self.name: list[str] = name
        self.targets: dict[str, list[str]] = {}
        for kind, target_name in targets:
            if kind in VALID_KIND:
                self.targets.setdefault(kind, []).append(target_name)

    def __bool__(self):
        return any(self.targets.values())


def pad_to_page(flat_output: Path):
    page_out = flat_output.parent.with_name("bin_page") / flat_output.name
    page_out.parent.mkdir(exist_ok=True)
    data = flat_output.read_bytes()
    padding = (PAGE_ALIGN - (len(data) % PAGE_ALIGN)) % PAGE_ALIGN
    page_out.write_bytes(data + PADDING_BYTE * padding)


if __name__ == "__main__":
    main()
