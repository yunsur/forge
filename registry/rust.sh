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

    fetch "rust" "${RUST_DIST}/rust-${latest}-${arch}.tar.gz" "tar.gz" "flat"
    # 运行 install.sh
    local extracted
    extracted=$(find "$TOOLS_DIR/rust" -maxdepth 1 -type d -name 'rust-*' | head -1)
    if [ -n "$extracted" ]; then
        "$extracted/install.sh" --prefix="$TOOLS_DIR/rust" --without=rust-docs 2>&1 | tail -3
        rm -rf "$extracted"
    fi
    link_binary "$TOOLS_DIR/rust/bin/rustc"
    link_binary "$TOOLS_DIR/rust/bin/cargo"
    link_binary "$TOOLS_DIR/rust/bin/rustup"
    link_binary "$TOOLS_DIR/rust/bin/rustfmt"
    link_binary "$TOOLS_DIR/rust/bin/cargo-clippy" "cargo-clippy"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/rust"
    mkdir -p "$dest"
    tar -xzf "$file" -C "$TMP_DIR"
    local extracted
    extracted=$(find "$TMP_DIR" -maxdepth 1 -type d -name 'rust-*' | head -1)
    [ -n "$extracted" ] && "$extracted/install.sh" --prefix="$dest" --without=rust-docs 2>&1 | tail -3
    rm -rf "$extracted"
    link_binary "$dest/bin/rustc"
    link_binary "$dest/bin/cargo"
    link_binary "$dest/bin/rustup"
    link_binary "$dest/bin/rustfmt"
    link_binary "$dest/bin/cargo-clippy" "cargo-clippy"
}
