#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: node
# @repo: nodejs/node


get_latest() {
    # Node LTS 版本，从 dist 获取最新 LTS
    curl -fsSL "https://nodejs.org/dist/index.json" 2>/dev/null \
        | python3 -c "
import json,sys
for d in json.load(sys.stdin):
    if d.get('lts') and d['lts'] is not False:
        print(d['version'].lstrip('v')); break
" 2>/dev/null || true
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "Node.js ${latest}"
    local dest="$TOOLS_DIR/node"
    mkdir -p "$dest"
    local node_arch="x64"
    [ "$ARCH" = "aarch64" ] && node_arch="arm64"
    curl -fSL -o "$TMP_DIR/node.tar.gz" \
        "https://nodejs.org/dist/v${latest}/node-v${latest}-linux-${node_arch}.tar.gz"
    tar -xzf "$TMP_DIR/node.tar.gz" -C "$dest" --strip-components=1
    rm -f "$TMP_DIR/node.tar.gz"
    link_binary "$TOOLS_DIR/node/bin/node"
    link_binary "$TOOLS_DIR/node/bin/npm"
    link_binary "$TOOLS_DIR/node/bin/npx"
    ok "node"
}
