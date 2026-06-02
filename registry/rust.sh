#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: rust
# @desc: 下载 Rust 工具链

RUST_DIST="https://static.rust-lang.org/dist"

get_latest() {
    curl -fsSL "${RUST_DIST}/channel-rust-stable.toml" 2>/dev/null \
        | grep -A1 '\[pkg\.rust\]' \
        | grep 'version' \
        | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+).*/\1/' \
        | head -1
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新 Rust 版本"; exit 1; }

    local arch="x86_64-unknown-linux-gnu"
    [ "$ARCH" = "aarch64" ] && arch="aarch64-unknown-linux-gnu"

    fetch "rust" "${RUST_DIST}/rust-${latest}-${arch}.tar.xz" "tar.xz" "strip1"
    # tarball 结构: rustc/bin/rustc, cargo/bin/cargo, etc.
    link_binary "$TOOLS_DIR/rust/rustc/bin/rustc"
    link_binary "$TOOLS_DIR/rust/cargo/bin/cargo"
    link_binary "$TOOLS_DIR/rust/cargo/bin/rustup"
    link_binary "$TOOLS_DIR/rust/cargo/bin/rustfmt"
    link_binary "$TOOLS_DIR/rust/cargo/bin/cargo-clippy" "cargo-clippy"
}

install_from() {
    local file="$1"
    install_from_file "$file" "rust" "tar.xz" "strip1"
    # tarball 结构: rustc/bin/rustc, cargo/bin/cargo, etc.
    link_binary "$TOOLS_DIR/rust/rustc/bin/rustc"
    link_binary "$TOOLS_DIR/rust/cargo/bin/cargo"
    link_binary "$TOOLS_DIR/rust/cargo/bin/rustup"
    link_binary "$TOOLS_DIR/rust/cargo/bin/rustfmt"
    link_binary "$TOOLS_DIR/rust/cargo/bin/cargo-clippy" "cargo-clippy"
}
