#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: ast-grep
# @repo: ast-grep/ast-grep


get_latest() { github_latest "ast-grep/ast-grep"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "amd64" ] && arch="x86_64"
    fetch "ast-grep" \
        "https://github.com/ast-grep/ast-grep/releases/download/${latest}/app-${arch}-unknown-linux-gnu.zip" \
        "zip" "flat-binary" "sg"
    link_binary "$TOOLS_DIR/ast-grep/sg" "sg"
}
