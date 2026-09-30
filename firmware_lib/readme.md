# XT_RISC-V 微控制器 固件库

- [外设访问包(Peripheral Access Crate, PAC)](rust-pac)
- [微架构支持库](xt-riscv-mcu)
- [HAL库](rust-hal)
- CMSIS-Pack[闪存算法](flash-algorithm)(可以在probe-rs上正常使用)
- [芯片/寄存器描述(SystemRDL格式)](chip_desc)
- [C语言固件库**已停止维护**](c)

PAC使用[xt_rdl2rust](https://codeberg.org/XuanTongYao/xt_rdl2rust)工具从寄存器描述文件自动生成

## 汇编第一级自举

纯汇编编写的第一级[自举程序](asm_bootstrap)，进行了高度优化，仅使用至多128条汇编指令(**强烈推荐使用**)

## Rust

rust需要安装`riscv32i-unknown-none-elf`编译目标。为了使用构建脚本，还需要安装[`cargo-binutils`](https://github.com/rust-embedded/cargo-binutils)。同时为了在rust中使用中断处理函数，请选择`nightly`版本。详见[#111889](https://github.com/rust-lang/rust/issues/111889),[RFC 3246](https://github.com/rust-lang/rfcs/pull/3246)

项目根目录就是一个Cargo工作区，你可以直接在项目根目录执行编译或构建命令

同时还有一个使用Python编写的[Rust构建向导](../rs_build.py)脚本，快速构建可执行文件或生成纯二进制文件
