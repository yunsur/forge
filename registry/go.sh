#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: go
# @desc: 下载 Go 工具链

get_latest() {
    curl -fsSL "https://go.dev/dl/?mode=json" 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['version'])" 2>/dev/null \
        | sed 's/^go//'
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新 Go 版本"; exit 1; }

    local arch="amd64"; [ "$ARCH" = "aarch64" ] && arch="arm64"
    local url="https://go.dev/dl/go${latest}.linux-${arch}.tar.gz"
    fetch "go" "$url" "tar.gz" "strip1"
    link_binary "$TOOLS_DIR/go/bin/go"
    link_binary "$TOOLS_DIR/go/bin/gofmt"
}
