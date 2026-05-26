#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: openspec
# @repo: Fission-AI/OpenSpec


get_latest() {
    curl -fsSL "https://registry.npmjs.org/@fission-ai/openspec/latest" 2>/dev/null \
        | grep '"version"' | head -1 \
        | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true
}

upgrade() {
    command -v node &>/dev/null || { err "需要先安装 Node.js: forge install node"; exit 1; }
    command -v npm &>/dev/null  || { err "需要先安装 Node.js: forge install node"; exit 1; }

    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    fetch "openspec" \
        "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${latest}.tgz" \
        "tgz" "flat"
    npm install -g "$TOOLS_DIR/openspec/package" --prefix "$TOOLS_DIR/openspec" 2>/dev/null
    rm -rf "$TOOLS_DIR/openspec/package"
    link_binary "$TOOLS_DIR/openspec/bin/openspec"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/openspec"
    mkdir -p "$dest"
    tar -xzf "$file" -C "$dest"
    npm install -g "$dest/package" --prefix "$dest" 2>/dev/null
    rm -rf "$dest/package"
    link_binary "$dest/bin/openspec"
}
