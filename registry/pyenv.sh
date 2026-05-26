#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: pyenv
# @repo: pyenv/pyenv


get_latest() { local tag; tag=$(github_latest "pyenv/pyenv"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    local dest="$RUNTIMES_DIR/pyenv"
    fetch "pyenv" \
        "https://github.com/pyenv/pyenv/archive/refs/tags/v${latest}.tar.gz" \
        "tar.gz" "strip1"
    fetch_to "$dest/plugins/pyenv-virtualenv" \
        "https://github.com/pyenv/pyenv-virtualenv/archive/refs/heads/master.tar.gz" \
        "tar.gz" "strip1"
    link_binary "$RUNTIMES_DIR/pyenv/bin/pyenv"
}

install_from() {
    local file="$1"
    local dest="$RUNTIMES_DIR/pyenv"
    mkdir -p "$dest"
    tar -xzf "$file" -C "$dest" --strip-components=1
    # pyenv-virtualenv 由 forge install 单独下载，此处只处理 pyenv 主体
    link_binary "$RUNTIMES_DIR/pyenv/bin/pyenv"
}
