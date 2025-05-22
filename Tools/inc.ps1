# 用户自定义程序
$program_paths = @(
    ".\tests"
)
$program_files = @()
$program_files_full = @()
foreach ($path in $program_paths) {
    $program_files += @(Get-ChildItem -Path $path -Filter *".c" | ForEach-Object { $_.Name })
    $program_files_full += @(Get-ChildItem -Path $path -Filter *".c" | ForEach-Object { $_.FullName })
}
$verify_files = @(Get-ChildItem -Path ".\tests\Verification" -Filter *".c" | ForEach-Object { $_.Name })
$verify_files_full = @(Get-ChildItem -Path ".\tests\Verification" -Filter *".c" | ForEach-Object { $_.FullName })
$main_files = $program_files + $verify_files
$main_files_full = $program_files_full + $verify_files_full


# 包含相关
$include_paths = @(
    ".\C_lib\XT_RISC_V"
    ".\C_lib\XT_RISC_V\Peripherals"
    ".\C_lib\XT_RISC_V\WISHBONE"
    ".\C_lib\XT_RISC_V\XT_LB"
)

$compile_list = @()
foreach ($path in $include_paths) {
    $compile_list += @(Get-ChildItem -Path $path -Filter *".c" | ForEach-Object { $_.FullName })
}

$include_list = $include_paths | ForEach-Object { "-I $_" -split ' ', 2 }


# 创建输出文件夹
$输出目录 = ".\build"
$folderPaths = @(
    $输出目录
    $输出目录 + "\ELFs"
    $输出目录 + "\ELFs\Verification"
    $输出目录 + "\FlatBinary"
    $输出目录 + "\FlatBinary\Verification"
    $输出目录 + "\FlatBinaryTxt"
    $输出目录 + "\FlatBinaryTxt\Verification"
)
foreach ($folderPath in $folderPaths) {
    if (!(Test-Path $folderPath)) { New-Item -ItemType Directory -Path $folderPath | Out-Null }
}
