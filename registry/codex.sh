#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: codex
# @repo: openai/codex


get_latest() {
    # tag 格式: rust-v0.133.0，去掉 rust- 和 v 前缀
    local tag; tag=$(github_latest "openai/codex")
    tag="${tag#rust-}"
    echo "${tag#v}"
}

upgrade() {
    local latest
    latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="x86_64"
    [ "$ARCH" = "aarch64" ] && arch="aarch64"
    local tag="rust-v${latest}"

    fetch "codex" \
        "https://github.com/openai/codex/releases/download/${tag}/codex-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "flat"
    # tarball 内为单文件 codex-<arch>-unknown-linux-musl，需重命名
    local src_bin="$TOOLS_DIR/codex/codex-${arch}-unknown-linux-musl"
    if [ -f "$src_bin" ] && [ ! -f "$TOOLS_DIR/codex/codex" ]; then
        mv "$src_bin" "$TOOLS_DIR/codex/codex"
    fi
    chmod +x "$TOOLS_DIR/codex/codex" 2>/dev/null || true
    link_binary "$TOOLS_DIR/codex/codex"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/codex"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" || { err "codex 解压失败"; return 1; }
    # tarball 内为单文件 codex-<arch>-unknown-linux-musl，需重命名
    local src_bin
    src_bin=$(find "$dest" -maxdepth 1 -name "codex-*" -type f | head -1)
    if [ -n "$src_bin" ] && [ "$src_bin" != "$dest/codex" ]; then
        mv "$src_bin" "$dest/codex"
    fi
    chmod +x "$dest/codex" 2>/dev/null || true
    link_binary "$dest/codex"
}
