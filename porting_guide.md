# RTL移植手册

当您需要将处理器内核的RTL代码移植到其他设备上（或仿真器）时，请仔细阅读以下内容。

## 所需的代码文件

您最好将下列的所有文件都添加到您的工程中。

1. 所有与RISC-V相关的内容（包括处理器内核）都在[RISC-V](RTL/RISC-V)目录中，处理器内核模块是[RISC_V_Core](RTL/RISC-V/RISC_V_Core.sv)。
2. [Utils](RTL/Utils)目录包含了许多通用模块，Jtag调试模块会使用其中的部分模块。
3. 内核模块使用了直接访存接口[memory_if.sv](RTL/Ifs/memory_if.sv)（直接输出访存位宽、地址等信号的接口）。

## 实例化内核模块

内核模块有4个参数可供设置：

- `PC_RESET`: 设置PC寄存器的复位值（复位向量）
- `STALL_REQ_COUNT`: 外部可向内核发出暂停请求的信号数量。发出暂停请求时会暂停流水线。
- `INST_FETCH_REG`: 指示读取指令时，指令是否已经经过寄存器延迟了一个时钟周期。若为`1'b1`则流水线的`IF_ID`模块将不会生成指令的中间寄存器。
- `CFG`: 内核的配置参数。具体位于[CoreConfig.sv](RTL/RISC-V/Pkgs/CoreConfig.sv)文件中。可用于配置[misa寄存器](https://docs.riscv.org/reference/isa/v20260120/priv/machine.html#misa)中的内核位宽与扩展字段。目前仅实现了其中的[E标志](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32e.html)。暂不支持设置位宽。

如果您不需要从外部暂停内核流水线。应该把`stall_req`信号设为0。

如果您不需要使用自定义外部中断控制器的中断重定向功能。请修改[ExceptionCtrl](RTL/RISC-V/Core/ExceptionCtrl.sv)文件的`code = mint.custom_int_code;`以及其他的相关代码。

如果您不需要使用中断与Jtag调试器，请参考ACT4的[仿真代码](ACT4/xt_rv32i_sim/HDL/tb/XT_RV32I_Act_tb.sv)。声明相关的接口但将中断和调试器信号都设为0。

## 其他可移植模块

下面只列出了一些主要的模块。

如果您使用不同的总线协议，请根据实际情况修改它们的总线接口与内部寄存器地址。

- [External_INT_Ctrl](RTL/SOC/SystemPeripherals/External_INT_Ctrl.sv): 自定义外部中断控制器
- [SoftwareINT](RTL/SOC/SystemPeripherals/SoftwareINT.sv): msip(软件中断寄存器)
- [SystemTimer](RTL/SOC/SystemPeripherals/SystemTimer.sv): mtime和mtimecmp(机器模式定时器寄存器)
- [UART_BUS](RTL/SOC/SystemPeripherals/UART_BUS.sv): Uart外设
- [AF_GPIO_BUS](RTL/SOC/BUS_Peripherals/AF_GPIO_BUS.sv): 功能复用GPIO，支持仅输入/仅输出的功能复用(暂不支持双向功能`inout`的复用)。
- [LEDSD_Direct](RTL/SOC/Peripherals/LEDSD_Direct.sv): 7段LED数码管译码器
- [LEDSD_Direct_LBUS](RTL/SOC/BUS_Peripherals/LEDSD_Direct_LBUS.sv): 7段LED数码管译码器的总线包装版本
