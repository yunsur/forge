#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

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

    # 平台
    local platform="linux-x64"
    [ "$ARCH" = "aarch64" ] && platform="linux-arm64"

    _log "下载" "Claude Code ${latest} (${platform})"

    local dest="$TOOLS_DIR/claude"
    mkdir -p "$dest"
    local tmp="$TMP_DIR/claude"

    # 获取 manifest checksum
    local manifest_json checksum
    manifest_json=$(curl -fsSL "$DOWNLOAD_BASE/$latest/manifest.json" 2>/dev/null || true)
    if [ -n "$manifest_json" ]; then
        checksum=$(echo "$manifest_json" \
            | grep -o "\"$platform\"[^}]*\"checksum\"[[:space:]]*:[[:space:]]*\"[a-f0-9]\{64\}\"" \
            | grep -o '[a-f0-9]\{64\}' || true)
    fi

    # 下载
    curl -fSL -o "$tmp" "$DOWNLOAD_BASE/$latest/$platform/claude"

    # 校验
    if [ -n "$checksum" ]; then
        local actual
        actual=$(sha256sum "$tmp" | cut -d' ' -f1)
        if [ "$actual" != "$checksum" ]; then
            rm -f "$tmp"
            err "校验失败 (期望: $checksum  实际: $actual)"
            exit 1
        fi
    fi

    chmod +x "$tmp"
    mv "$tmp" "$dest/claude"
    link_binary "$TOOLS_DIR/claude/claude"

    # 更新版本
    ok "claude $latest"
}
