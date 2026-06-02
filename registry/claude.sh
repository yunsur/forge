#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: claude
# @repo: anthropics/claude-code


DOWNLOAD_BASE="https://downloads.claude.ai/claude-code-releases"

get_latest() {
    curl -fsSL "$DOWNLOAD_BASE/latest" 2>/dev/null | tr -d '[:space:]'
}

upgrade() {
    local latest
    latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }

    local platform="linux-x64"
    [ "$ARCH" = "aarch64" ] && platform="linux-arm64"

    _DOWNLOAD_FILENAME="claude-${latest}-${platform}"
    fetch "claude" \
        "$DOWNLOAD_BASE/$latest/$platform/claude" \
        "binary" "" "claude"
    link_binary "$TOOLS_DIR/claude/claude"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/claude"
    mkdir -p "$dest"
    cp "$file" "$dest/claude"
    chmod +x "$dest/claude"
    link_binary "$TOOLS_DIR/claude/claude"
}
