import subprocess, sys
from pathlib import Path
from json import loads
from argparse import ArgumentParser

# ===================== 默认配置 ====================
DEFAULT_NAME = "uart"
TARGET_TRIPLE = "riscv32i-unknown-none-elf"  # target 要与config.toml里的相同
PAGE_ALIGN = 16  # 页的对齐字节数
PADDING_BYTE = b"\x00"  # 对齐填充数据
# ===================================================


def main():
    args = parse_args()
    # print(args)
    cmds = wizard(args)
    cargo(**cmds)


# 定义有效的命令、模式和种类
VALID_CMD_ALIAS = ["b", "r"]
VALID_CMDS = ["objdump", "objcopy", "build", "run"]
VALID_KIND = ["bin", "example", "test", "bench"]

DEFAULT_E_ARGS = {
    "objcopy": "-O binary",
    "objdump": "-d --no-show-raw-insn --print-imm-hex -M no-aliases",
}


def cargo(
    cmd: str,
    release: bool,
    kind: str,
    name: str,
    features=None,
    overide=None,
    additional="",
):

    rel = "--release" if release else ""
    features = ["-F", features] if features else []
    passed_args = overide if overide else DEFAULT_E_ARGS.get(cmd, "")

    args = [
        *f"cargo {cmd} {rel} --{kind}".split(),
        name,
        *features,
        *f"-- {passed_args} {additional}".split(),
    ]

    mode = "release" if release else "debug"
    bin_path = Path(f"target/{TARGET_TRIPLE}/{mode}/bin/{name}.bin")
    bin_path.parent.mkdir(exist_ok=True)
    if cmd == "objcopy":
        args.append(str(bin_path))

    subprocess.run(args, check=True)

    if cmd == "objcopy":
        pad_to_page(bin_path)


def wizard(args: dict):

    no_target = not any(args.get(key) for key in VALID_KIND)

    pts = get_targets()
    if not any(pts) and no_target:
        print("当前无编译目标")
        quit()

    if "cmd" not in args:
        args["cmd"] = select_item(VALID_CMDS, "\n选择执行命令:")

    if no_target:
        kinds = list(dict.fromkeys(key for p in pts for key in p.targets))
        kind: str = select_item(kinds, "\n选择种类:")
        targets = []
        for pt in pts:
            if t := pt.targets.get(kind):
                targets.extend(t)
        args[kind] = select_item(targets, "\n选择目标:")

    kind: str = next(k for k, v in args.items() if k in VALID_KIND and v)
    features = args["features"]
    passed_args = args["passed_args"]
    additional = args["additional"]
    return {
        "cmd": args["cmd"],
        "release": args["release"],
        "kind": kind,
        "name": args[kind],
        "features": features if features else None,
        "overide": "".join(passed_args) if passed_args else None,
        "additional": "".join(additional) if additional else "",
    }


def parse_args():
    """解析命令行参数"""

    parser = ArgumentParser(description="rust构建向导")

    all_cmds = (*VALID_CMD_ALIAS, *VALID_CMDS)
    if len(sys.argv) >= 2 and sys.argv[1] in all_cmds:
        parser.add_argument("cmd", choices=all_cmds)

    parser.add_argument("-r", "--release", action="store_true")
    target_group = parser.add_mutually_exclusive_group()
    for i in VALID_KIND:
        target_group.add_argument(f"--{i}")

    parser.add_argument("-F", "--features", type=str)
    parser.add_argument("-+", "--additional", nargs="*", type=str)
    parser.add_argument("passed_args", nargs="*", type=str)

    return vars(parser.parse_args())


def select_num(options: list, prompt: object = ""):
    if len(options) == 1:
        return 0
    p = f"{prompt}\n{"\n".join(f"{i}\t->\t{t}" for i,t in enumerate(options))}\n> "
    n = input(p)
    return int(n) if n.isdigit() else 0


def select_item(options: list, prompt: object = ""):
    return options[select_num(options, prompt)]


def get_targets():
    ret = subprocess.run(
        f"cargo metadata --no-deps -q".split(),
        check=True,
        capture_output=True,
        encoding="utf-8",
    )
    packages: dict = loads(ret.stdout)["packages"]

    targets = (
        (p["name"], [(t["kind"][0], t["name"]) for t in p["targets"]]) for p in packages
    )
    return [PackageTargets(t[0], t[1]) for t in targets]


class PackageTargets:
    def __init__(self, name, targets) -> None:
        self.name: list[str] = name
        self.targets: dict[str, list[str]] = {}
        for kind, name in targets:
            if kind in VALID_KIND:
                self.targets.setdefault(kind, list()).append(name)

    def __bool__(self):
        return any(self.targets.values())


def pad_to_page(flat_output: Path):
    page_out = flat_output.parent.with_name("bin_page") / flat_output.name
    page_out.parent.mkdir(exist_ok=True)
    with open(flat_output, "rb") as f, open(page_out, "wb") as out:
        binary_data = f.read()
        padding = (PAGE_ALIGN - (len(binary_data) % PAGE_ALIGN)) % PAGE_ALIGN
        out.write(binary_data)
        for _ in range(padding):
            out.write(PADDING_BYTE)


if __name__ == "__main__":
    main()
