#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: rg
# @repo: BurntSushi/ripgrep


get_latest() { github_latest "BurntSushi/ripgrep"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "rg" \
        "https://github.com/BurntSushi/ripgrep/releases/download/${latest}/ripgrep-${latest}-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/rg/rg"
}
