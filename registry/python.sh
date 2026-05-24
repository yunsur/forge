#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: python
# @desc: 下载 CPython 源码，供 pyenv 编译安装

VERSION="3.11.6"
PYTHON_ORG="https://www.python.org/ftp/python"

get_latest() { echo "$VERSION"; }

upgrade() {
    local ver="$VERSION"
    _log "下载" "CPython ${ver} 源码"

    local dest="$RUNTIMES_DIR/python"
    mkdir -p "$dest"

    local url="${PYTHON_ORG}/${ver}/Python-${ver}.tar.xz"
    curl -fSL -o "${dest}/Python-${ver}.tar.xz" "$url"

    ok "CPython ${ver} 源码 → ${dest}/Python-${ver}.tar.xz"
    echo ""
    echo "  安装: PYTHON_BUILD_CACHE_PATH=${dest} pyenv install ${ver}"
}
