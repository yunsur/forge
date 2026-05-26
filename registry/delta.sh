#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: delta
# @repo: dandavison/delta


get_latest() { github_latest "dandavison/delta"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "delta" \
        "https://github.com/dandavison/delta/releases/download/${latest}/delta-${latest}-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/delta/delta"
}

install_from() {
    local file="$1"
    install_from_file "$file" "delta" "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/delta/delta"
}
