#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: starship
# @repo: starship/starship


get_latest() { local tag; tag=$(github_latest "starship/starship"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="x86_64"
    [ "$ARCH" = "aarch64" ] && arch="aarch64"
    fetch "starship" \
        "https://github.com/starship/starship/releases/download/v${latest}/starship-${arch}-unknown-linux-musl.tar.gz" \
        "tar.gz" "flat"
    link_binary "$TOOLS_DIR/starship/starship"
}

install_from() {
    local file="$1"
    install_from_file "$file" "starship" "tar.gz" "flat"
    link_binary "$TOOLS_DIR/starship/starship"
}
