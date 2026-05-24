#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: pyenv
# @repo: pyenv/pyenv


get_latest() { local tag; tag=$(github_latest "pyenv/pyenv"); echo "${tag#v}"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "pyenv ${latest}"
    local dest="$RUNTIMES_DIR/pyenv"
    mkdir -p "$dest"
    curl -fSL -o "$TMP_DIR/pyenv.tar.gz" \
        "https://github.com/pyenv/pyenv/archive/refs/tags/v${latest}.tar.gz"
    tar -xzf "$TMP_DIR/pyenv.tar.gz" -C "$dest" --strip-components=1
    _log "下载" "pyenv-virtualenv"
    curl -fSL -o "$TMP_DIR/pyenv-virtualenv.tar.gz" \
        "https://github.com/pyenv/pyenv-virtualenv/archive/refs/heads/master.tar.gz"
    mkdir -p "$dest/plugins/pyenv-virtualenv"
    tar -xzf "$TMP_DIR/pyenv-virtualenv.tar.gz" -C "$dest/plugins/pyenv-virtualenv" --strip-components=1
    rm -f "$TMP_DIR/pyenv.tar.gz" "$TMP_DIR/pyenv-virtualenv.tar.gz"
    link_binary "$RUNTIMES_DIR/pyenv/bin/pyenv"
    ok "pyenv"
}
