#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

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
    local node_arch="x64"
    [ "$ARCH" = "aarch64" ] && node_arch="arm64"
    fetch "node" \
        "https://nodejs.org/dist/v${latest}/node-v${latest}-linux-${node_arch}.tar.gz" \
        "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/node/bin/node"
    link_binary "$TOOLS_DIR/node/bin/npm"
    link_binary "$TOOLS_DIR/node/bin/npx"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/node"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" --strip-components=1 || { err "node 解压失败"; return 1; }
    link_binary "$TOOLS_DIR/node/bin/node"
    link_binary "$TOOLS_DIR/node/bin/npm"
    link_binary "$TOOLS_DIR/node/bin/npx"
}
