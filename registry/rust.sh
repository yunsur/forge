#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

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

    local url="${RUST_DIST}/rust-${latest}-${arch}.tar.gz"
    _log "下载" "rust ${latest}"
    local dest="$TOOLS_DIR/rust"
    mkdir -p "$dest"
    curl -fSL -o "$TMP_DIR/rust.tar.gz" "$url"
    tar -xzf "$TMP_DIR/rust.tar.gz" -C "$TMP_DIR"
    # 安装到 dest
    "$TMP_DIR/rust-${latest}-${arch}/install.sh" \
        --prefix="$dest" \
        --without=rust-docs 2>&1 | tail -3
    rm -rf "$TMP_DIR/rust-${latest}-${arch}" "$TMP_DIR/rust.tar.gz"

    link_binary "$dest/bin/rustc"
    link_binary "$dest/bin/cargo"
    link_binary "$dest/bin/rustup"
    link_binary "$dest/bin/rustfmt"
    link_binary "$dest/bin/cargo-clippy" "cargo-clippy"
    ok "rust ${latest}"
}
