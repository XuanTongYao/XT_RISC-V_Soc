fn main() {
    println!("cargo:rustc-link-arg=--nmagic"); // 禁用页对齐 降低elf文件大小
    println!("cargo:rustc-link-arg=--relax-gp");

    // 链接器脚本
    use std::{env, fs, path::PathBuf};
    let links = ["link.x", "trap_handler.x"];
    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let out = PathBuf::from(env::var("OUT_DIR").unwrap());
    for link in links {
        let src = manifest.join(link);
        let dst = out.join(link);
        println!("cargo:rustc-link-arg=-T{}", src.display());
        println!("cargo:rerun-if-changed={}", src.display());
        fs::copy(&src, &dst).unwrap();
    }
    println!("cargo:rustc-link-search={}", out.display());
}
