fn main() {
    println!("cargo:rustc-link-arg=--nmagic"); // 禁用页对齐 降低elf文件大小
    println!("cargo:rustc-link-arg=--relax-gp");

    // 链接器脚本
    let links = ["link.x", "trap_handler.x", "defmt.x"];
    for link in links {
        println!("cargo:rustc-link-arg=-T{}", link);
        println!("cargo:rerun-if-changed={}", link);
    }
}
