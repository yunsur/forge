#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: yq
# @repo: mikefarah/yq


get_latest() { local tag; tag=$(github_latest "mikefarah/yq"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local arch="$ARCH"; [ "$arch" = "aarch64" ] && arch="arm64"
    fetch "yq" \
        "https://github.com/mikefarah/yq/releases/download/v${latest}/yq_linux_${arch}.tar.gz" \
        "tar.gz" "flat-binary" "yq"
    link_binary "$TOOLS_DIR/yq/yq"
}

install_from() {
    local file="$1"
    install_from_file "$file" "yq" "tar.gz" "flat-binary" "yq"
    link_binary "$TOOLS_DIR/yq/yq"
}
