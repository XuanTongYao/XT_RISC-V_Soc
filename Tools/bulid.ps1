# 请确保你已经安装好编译器并设置环境变量
# riscv64-unknown-elf-gcc --version
# riscv-none-elf-gcc --version
Write-Output ""
$parentDir = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location -Path $parentDir
. "$PSScriptRoot/inc.ps1"
#  -fstrict-volatile-bitfields
# 对具有volatile修饰的位域或结构体的成员，严格按照其大小执行单次访问，而不是使用lw这种更高效的访问方式
$架构与扩展 = "-march=rv32i_zicsr -mabi=ilp32"
$库参数 = "-nostdlib"
$其他参数 = "-fstrict-volatile-bitfields"
$riscv编译参数 = "$架构与扩展 $库参数 $其他参数" -split ' '
$优化等级 = "-Os"
$链接优化 = "-flto"
# 修改$全局变量区记得修改启动文件
$全局变量区 = "0x844"
$链接器参数 = "-Wl,-Ttext-segment=0x0,-Tdata=$全局变量区,--section-start=.init=0x0"
$编译器 = "riscv-none-elf-gcc"
$目标文件处理工具 = "riscv-none-elf-objcopy"

$start_file = ".\C_lib\Startup\start.s"
# $start_file = ".\C_lib\Startup\simple_start.s"


Write-Output "程序:"
for ($i = 0; $i -lt $main_files.Count; $i++) {
    if ($i -eq $program_files.Count) {
        Write-Output "功能验证:"
    }
    Write-Output "$i->$($main_files[$i])"
}
$index = Read-Host -Prompt "选择主文件"
if ($index.Equals("")) { $index = 0 }

$main_file = $main_files_full[$index]
$main_file_name = $main_files[$index]
if ($index -ge $program_files.Count) {
    $main_file_name = "Verification\" + $main_file_name
}
$输出文件 = $main_file_name.TrimEnd(".c") + $优化等级

# 编译链接生成ELF
$elf_output = "$输出目录\ELFs\" + $输出文件
&$编译器 $链接器参数 $riscv编译参数 $优化等级 $链接优化 `
    $include_list $start_file -x c $main_file $compile_list `
    -e _start -o $elf_output


# 生成纯指令二进制文件
$flat_output = "$输出目录\FlatBinary\" + $输出文件 + ".bin"
&$目标文件处理工具 -O binary $elf_output $flat_output


##### 生成16进制文本文件
# 定义文件路径
$outputFilePath = "$输出目录\FlatBinaryTxt\" + $输出文件 + ".txt"

# 打开文件流读取前4个字节
$stream = [System.IO.File]::OpenRead($flat_output)
for ($i = 0; $i -lt ($stream.Length / 4); $i++) {
    $buffer = New-Object byte[] 4
    $bytesRead = $stream.Read($buffer, 0, 4)
    # 反转字节序
    [Array]::Reverse($buffer)
    # 将字节转换为16进制字符串
    $hexString = -join ($buffer | ForEach-Object { "{0:X2}" -f $_ })
    # 将16进制字符串写入到新文件中
    if ($i -eq 0) {
        Set-Content -Path $outputFilePath -Value $hexString
    }
    else {
        Add-Content -Path $outputFilePath -Value $hexString
    }
}
$stream.Close()


# 16字节对齐填充
$filePath = $flat_output
$outputPath = $flat_output

# 读取二进制文件
$originalBytes = [System.IO.File]::ReadAllBytes($filePath)

# 计算填充字节数
$originalLength = $originalBytes.Length
$padding = (16 - ($originalLength % 16)) % 16

if ($padding -gt 0) {
    # 创建新数组并复制原数据
    $newBytes = New-Object byte[] ($originalLength + $padding)
    [System.Array]::Copy($originalBytes, $newBytes, $originalLength)
}
else {
    $newBytes = $originalBytes
}

# 写入新文件
[System.IO.File]::WriteAllBytes($outputPath, $newBytes)


