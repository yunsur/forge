#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: python
# @desc: 下载 CPython 源码，供 pyenv 编译安装

VERSION="3.11.6"
PYTHON_ORG="https://www.python.org/ftp/python"

get_latest() { echo "$VERSION"; }

upgrade() {
    local ver="$VERSION"
    local dest="$RUNTIMES_DIR/python"
    mkdir -p "$dest"
    fetch_to "$dest" \
        "${PYTHON_ORG}/${ver}/Python-${ver}.tar.xz" \
        "binary" "" "Python-${ver}.tar.xz"
    echo ""
    echo "  安装: PYTHON_BUILD_CACHE_PATH=${dest} pyenv install ${ver}"
}

install_from() {
    local file="$1"
    local dest="$RUNTIMES_DIR/python"
    mkdir -p "$dest"
    cp "$file" "$dest/Python-${VERSION}.tar.xz"

    # 实际编译安装 Python
    local pyenv_root="$RUNTIMES_DIR/pyenv"
    if [ -x "$pyenv_root/bin/pyenv" ]; then
        # 强制使用 forge 路径，不使用默认 ~/.pyenv
        export PYENV_ROOT="$pyenv_root"
        export PATH="$pyenv_root/bin:$PATH"
        export PYTHON_BUILD_CACHE_PATH="$dest"

        # 检查是否已安装该版本
        if ! "$pyenv_root/bin/pyenv" versions --bare 2>/dev/null | grep -q "^${VERSION}$"; then
            echo "  编译安装 Python ${VERSION}..."
            "$pyenv_root/bin/pyenv" install "$VERSION" || {
                err "Python ${VERSION} 安装失败"
                return 1
            }
        fi

        # 设置为全局版本
        "$pyenv_root/bin/pyenv" global "$VERSION" 2>/dev/null || true
        unset PYTHON_BUILD_CACHE_PATH
    else
        warn "pyenv 未安装，跳过 Python 编译（请先安装 pyenv）"
    fi
}
