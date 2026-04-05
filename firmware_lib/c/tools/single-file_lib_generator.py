# 单文件库注释生成
from pathlib import Path
from tomllib import load
from typing import Any
from os import chdir

# 改到项目目录
chdir(Path(__file__).parent.parent.parent.parent.resolve())

默认地址域算法 = "#define DOMAIN_BASE(StartID) (0+((StartID)<<(12)))"


def main():
    cfgs = Path.cwd().rglob("firmware_lib/c/*.toml")
    for i in cfgs:
        print(i)
        create_header(i)


def create_header(config_file: Path):
    with open(config_file, "rb") as file:
        config = load(file)
    if not config.get("lib_cfg"):
        return
    file_name: str = config["file_name"]
    features: list[str] = [f.upper() for f in config["features"]]
    header: str = config["file_name"].upper()
    lib: str = config["lib_name"].upper()

    exclude_define = [f"{lib}_NO_{f}" for f in features]
    only_define = [f"{lib}_ONLY_{f}" for f in features]

    # 文件简述
    abstract = f"""/*  {file_name} - {config["version"]} - {config["description"]}

    - 使用方法: 参照如下代码，在包含头文件前定义`IMPLEMENTATION`实现宏
    
    #define {header}_IMPLEMENTATION
    #include "{file_name}.h"
    
|| ===========================================
||
|| 功能配置  在包含头文件前，定义以下宏
||
|| - 禁用部分功能:
{"\n".join([f"||       {i}" for i in exclude_define])}
||
|| - 仅启用部分功能:
{"\n".join([f"||       {i}" for i in only_define])}
||
|| ==========================================

*/
"""

    # 头文件
    domain_macros = domain(config.get("domain_id"))
    header_macros = f"""\n\n
#ifdef __EDITOR
#define {header}_IMPLEMENTATION
#include "c/type.h"
#endif
    
#ifndef INCLUDE_XT_RISCV_MCU_H
#define INCLUDE_XT_RISCV_MCU_H
//////////////   头文件开始   ////////////////////////////////////////
///
//

{domain_macros}


//
///
//////////////   头文件结束   ////////////////////////////////////////
#endif // INCLUDE_XT_RISCV_MCU_H
"""

    # 实现配置
    only_macros = ""
    for i, d in enumerate(only_define):
        if only_macros and not only_macros.isspace():
            if i % 3 == 0:
                only_macros += " \\\n"
            only_macros += " || "
        only_macros += f"defined({d})"

    implementation_macros = f"""\n\n\n
#ifdef {header}_IMPLEMENTATION

#if {only_macros}
{"\n".join([f"#ifndef {a}\n#define {b}\n#endif" for (a,b) in zip(only_define,exclude_define)])}
#endif


//----------实现开始----------//
{"\n\n\n".join([f"#ifndef {a}// 🟢实现{features[i]}\n\n#endif" for i,a in enumerate(exclude_define)])}
#endif  // {header}_IMPLEMENTATION
"""

    # 创建/覆盖头文件
    header_file = config_file.parent / f"{file_name}.h"
    if header_file.exists():
        if input(f"{file_name}.h 文件已经存在，是否覆盖?\nY/N -> ").upper() != "Y":
            return
    with open(header_file, "wt", encoding="utf-8") as file:
        file.write(abstract)
        file.write(header_macros)
        file.write(implementation_macros)


def domain(domain_id: dict[str, Any] | None):
    if domain_id is None:
        return ""
    name: str = domain_id["name"]
    start: int = domain_id["start"]
    end: int = domain_id["end"]

    defines = [f"OCCUPY_DOMAIN_{i}" for i in range(start, end)]
    check_macros = ""
    for i, d in enumerate(defines):
        if check_macros and not check_macros.isspace():
            if i % 3 == 0:
                check_macros += " \\\n"
            check_macros += " || "
        check_macros += f"defined({d})"
    return f"""\
#if {check_macros}
#error 重复使用地址域ID
#else
{"\n".join([f"#define {d}" for d in defines])}
#endif

#ifndef DOMAIN_BASE
{默认地址域算法}
#endif
#define DOMAIN_{name}_BASE DOMAIN_BASE({start})
"""


if __name__ == "__main__":
    main()
