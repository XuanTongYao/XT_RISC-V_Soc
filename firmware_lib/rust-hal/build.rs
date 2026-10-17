fn main() {
    println!("cargo:rustc-link-arg=--nmagic"); // 禁用页对齐 降低elf文件大小
    println!("cargo:rustc-link-arg=--relax-gp");

    // 链接器脚本
    let links = ["link.x", "device.x", "trap_handler.x"];
    for link in links {
        println!("cargo:rustc-link-arg=-T{}", link);
    }

    println!("cargo:rustc-link-arg-examples=-Tdefmt.x");
}
