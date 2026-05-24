#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: lazygit
# @repo: jesseduffield/lazygit


get_latest() { local tag; tag=$(github_latest "jesseduffield/lazygit"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"
    [ "$arch" = "amd64" ] && arch="x86_64"
    [ "$arch" = "aarch64" ] && arch="arm64"
    fetch "lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/download/v${latest}/lazygit_${latest}_Linux_${arch}.tar.gz" \
        "tar.gz" "flat-binary" "lazygit"
    link_binary "$TOOLS_DIR/lazygit/lazygit"
}
