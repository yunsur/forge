#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: eza
# @repo: eza-community/eza


get_latest() { local tag; tag=$(github_latest "eza-community/eza"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "eza" \
        "https://github.com/eza-community/eza/releases/download/v${latest}/eza_${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "flat-binary" "eza"
    link_binary "$TOOLS_DIR/eza/eza"
}
