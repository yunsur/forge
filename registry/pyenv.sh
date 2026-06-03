#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: pyenv
# @repo: pyenv/pyenv


get_latest() { local tag; tag=$(github_latest "pyenv/pyenv"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    export _DOWNLOAD_FILENAME="pyenv-${latest}.tar.gz"
    fetch "pyenv" \
        "https://github.com/pyenv/pyenv/archive/refs/tags/v${latest}.tar.gz" \
        "tar.gz" "strip1"
    unset _DOWNLOAD_FILENAME
    link_binary "$RUNTIMES_DIR/pyenv/bin/pyenv"
}

install_from() {
    local file="$1"
    local dest="$RUNTIMES_DIR/pyenv"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" --strip-components=1 || { err "pyenv 解压失败"; return 1; }
    link_binary "$RUNTIMES_DIR/pyenv/bin/pyenv"
}
