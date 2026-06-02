#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: uv
# @repo: astral-sh/uv


get_latest() { github_latest "astral-sh/uv"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "uv" \
        "https://github.com/astral-sh/uv/releases/download/${latest}/uv-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "strip1"
    chmod +x "$TOOLS_DIR/uv/uv" "$TOOLS_DIR/uv/uvx" 2>/dev/null || true
    link_binary "$TOOLS_DIR/uv/uv"
    link_binary "$TOOLS_DIR/uv/uvx"
}

install_from() {
    local file="$1"
    install_from_file "$file" "uv" "tar.gz" "strip1"
    chmod +x "$TOOLS_DIR/uv/uv" "$TOOLS_DIR/uv/uvx" 2>/dev/null || true
    link_binary "$TOOLS_DIR/uv/uv"
    link_binary "$TOOLS_DIR/uv/uvx"
}
