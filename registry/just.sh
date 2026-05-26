#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: just
# @repo: casey/just


get_latest() { github_latest "casey/just"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "just" \
        "https://github.com/casey/just/releases/download/${latest}/just-${latest}-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "flat-binary" "just"
    link_binary "$TOOLS_DIR/just/just"
}

install_from() {
    local file="$1"
    install_from_file "$file" "just" "tar.gz" "flat-binary" "just"
    link_binary "$TOOLS_DIR/just/just"
}
