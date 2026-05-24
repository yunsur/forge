#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: bat
# @repo: sharkdp/bat


get_latest() { local tag; tag=$(github_latest "sharkdp/bat"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "bat" \
        "https://github.com/sharkdp/bat/releases/download/v${latest}/bat-v${latest}-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/bat/bat"
}
