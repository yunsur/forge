#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: jq
# @repo: jqlang/jq


get_latest() {
    # tag 格式: jq-1.8.1，去掉 jq- 前缀
    local tag; tag=$(github_latest "jqlang/jq")
    echo "${tag#jq-}"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="amd64"; [ "$ARCH" = "aarch64" ] && arch="arm64"
    fetch "jq" \
        "https://github.com/jqlang/jq/releases/download/jq-${latest}/jq-linux-${arch}" \
        "binary" "jq"
    link_binary "$TOOLS_DIR/jq/jq"
}
