#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: gstack
# @repo: garrytan/gstack

get_latest() {
    # GStack 无 release/tag，使用最新 commit SHA（短）
    # 方式1: GitHub API
    local sha
    sha=$(curl $(_curl_opts) "https://api.github.com/repos/garrytan/gstack/commits?per_page=1" 2>/dev/null \
        | grep '"sha"' | head -1 \
        | sed -E 's/.*"sha"[[:space:]]*:[[:space:]]*"([a-f0-9]{7})[a-f0-9]*".*/\1/' || true)
    # 方式2: API 失败，从 HTML 解析
    if [ -z "$sha" ]; then
        sha=$(curl -fsSL "https://github.com/garrytan/gstack/commits/main" 2>/dev/null \
            | grep -oE '[a-f0-9]{40}' | head -1 \
            | cut -c1-7 || true)
    fi
    echo "$sha"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "GStack ${latest}"
    local dest="$TOOLS_DIR/gstack"
    rm -rf "$dest"
    git clone --depth 1 --single-branch \
        "https://github.com/garrytan/gstack.git" "$dest" 2>/dev/null
}
