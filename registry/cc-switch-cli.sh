#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: cc-switch-cli
# @repo: saladday/cc-switch-cli


get_latest() { github_latest "saladday/cc-switch-cli"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="x64"
    [ "$ARCH" = "aarch64" ] && arch="aarch64"
    fetch "cc-switch-cli" \
        "https://github.com/saladday/cc-switch-cli/releases/download/${latest}/cc-switch-cli-linux-${arch}-musl.tar.gz" \
        "tar.gz" "flat-binary" "cc-switch"
    link_binary "$TOOLS_DIR/cc-switch-cli/cc-switch"
}

install_from() {
    local file="$1"
    install_from_file "$file" "cc-switch-cli" "tar.gz" "flat-binary" "cc-switch"
    link_binary "$TOOLS_DIR/cc-switch-cli/cc-switch"
}
