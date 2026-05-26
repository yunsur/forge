#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: bun
# @repo: oven-sh/bun


get_latest() {
    local tag; tag=$(github_latest "oven-sh/bun")
    # tag 格式: bun-v1.3.14
    echo "${tag#bun-v}"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="x64"
    [ "$ARCH" = "aarch64" ] && arch="aarch64"
    fetch "bun" \
        "https://github.com/oven-sh/bun/releases/download/bun-v${latest}/bun-linux-${arch}.zip" \
        "zip" "flat-binary" "bun"
}

install_from() {
    local file="$1"
    install_from_file "$file" "bun" "zip" "flat-binary" "bun"
}
