#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: superpowers
# @repo: obra/superpowers

get_latest() {
    github_latest "obra/superpowers"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "Superpowers ${latest}"
    local dest="$TOOLS_DIR/superpowers"
    rm -rf "$dest"
    git clone --depth 1 --single-branch \
        "https://github.com/obra/superpowers.git" "$dest" 2>/dev/null
}
