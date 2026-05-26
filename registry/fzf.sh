#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: fzf
# @repo: junegunn/fzf


get_latest() { local tag; tag=$(github_latest "junegunn/fzf"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "aarch64" ] && arch="arm64"
    fetch "fzf" \
        "https://github.com/junegunn/fzf/releases/download/v${latest}/fzf-${latest}-linux_${arch}.tar.gz" \
        "tar.gz" "flat"
    link_binary "$TOOLS_DIR/fzf/fzf"
}

install_from() {
    local file="$1"
    install_from_file "$file" "fzf" "tar.gz" "flat"
    link_binary "$TOOLS_DIR/fzf/fzf"
}
