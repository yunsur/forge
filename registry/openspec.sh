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
    # tarball 解压为 package/ 目录，本地安装依赖后链接 bin
    (cd "$TOOLS_DIR/openspec/package" && npm install --omit=dev 2>/dev/null) \
        || { err "openspec npm install 失败"; return 1; }
    link_binary "$TOOLS_DIR/openspec/package/bin/openspec.js" "openspec"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/openspec"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" || { err "openspec 解压失败"; return 1; }
    # tarball 解压为 package/ 目录，本地安装依赖后链接 bin
    (cd "$dest/package" && npm install --omit=dev 2>/dev/null) \
        || { err "openspec npm install 失败"; return 1; }
    link_binary "$dest/package/bin/openspec.js" "openspec"
}
