#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

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
    _log "下载" "OpenSpec ${latest}"
    local dest="$TOOLS_DIR/openspec"
    mkdir -p "$dest"
    curl -fSL -o "$TMP_DIR/openspec.tgz" \
        "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${latest}.tgz"
    npm install -g "$TMP_DIR/openspec.tgz" --prefix "$dest" 2>/dev/null
    rm -f "$TMP_DIR/openspec.tgz"
    link_binary "$dest/bin/openspec"
    ok "openspec $latest"
}
