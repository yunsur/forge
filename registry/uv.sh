#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: uv
# @repo: astral-sh/uv


get_latest() { github_latest "astral-sh/uv"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "uv ${latest}"
    local dest="$TOOLS_DIR/uv"
    mkdir -p "$dest"
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    curl -fSL -o "$TMP_DIR/uv.tar.gz" \
        "https://github.com/astral-sh/uv/releases/download/${latest}/uv-${arch}-unknown-linux-musl.tar.gz"
    tar -xzf "$TMP_DIR/uv.tar.gz" -C "$dest"
    chmod +x "$dest"/uv* 2>/dev/null || true
    rm -f "$TMP_DIR/uv.tar.gz"
    link_binary "$TOOLS_DIR/uv/uv"
    link_binary "$TOOLS_DIR/uv/uvx"
    ok "uv"
}
