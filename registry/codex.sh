#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

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

    _log "下载" "Codex CLI ${latest}"

    local dest="$TOOLS_DIR/codex"
    mkdir -p "$dest"
    local tmp="$TMP_DIR/codex.tar.gz"

    # Codex 预编译二进制
    local arch="x86_64"
    [ "$ARCH" = "aarch64" ] && arch="aarch64"

    local tag="rust-${latest}"
    local url="https://github.com/openai/codex/releases/download/${tag}/codex-${arch}-unknown-linux-musl.tar.gz"
    curl -fSL -o "$tmp" "$url"
    tar -xzf "$tmp" -C "$dest"
    chmod +x "$dest"/codex* 2>/dev/null || true
    rm -f "$tmp"
    link_binary "$TOOLS_DIR/codex/codex"

    # 更新版本
    ok "codex $latest"
}
