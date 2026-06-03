#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: pyenv-virtualenv
# @repo: pyenv/pyenv-virtualenv


get_latest() { github_latest "pyenv/pyenv-virtualenv"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    export _DOWNLOAD_FILENAME="pyenv-virtualenv-${latest}.tar.gz"
    local dest="$RUNTIMES_DIR/pyenv/plugins/pyenv-virtualenv"
    fetch_to "$dest" \
        "https://github.com/pyenv/pyenv-virtualenv/archive/refs/tags/${latest}.tar.gz" \
        "tar.gz" "strip1"
    unset _DOWNLOAD_FILENAME
}

install_from() {
    local file="$1"
    local dest="$RUNTIMES_DIR/pyenv/plugins/pyenv-virtualenv"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" --strip-components=1 || { err "pyenv-virtualenv 解压失败"; return 1; }
}
