#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: speckit
# @repo: github/spec-kit

get_latest() { github_latest "github/spec-kit"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    fetch "speckit" \
        "https://api.github.com/repos/github/spec-kit/tarball/${latest}" \
        "tar.gz" "strip1"
    _install_speckit "$TOOLS_DIR/speckit"
}

install_from() {
    local file="$1"
    local dest="$TOOLS_DIR/speckit"
    mkdir -p "$dest"
    _tar_quiet tar -xzf "$file" -C "$dest" --strip-components=1 \
        || { err "speckit 解压失败"; return 1; }
    _install_speckit "$dest"
}

_install_speckit() {
    local dest="$1"
    # 用 pyenv 的 python -m pip 安装，确保使用 pyenv 管理的 Python 环境
    command -v python &>/dev/null || { err "需要先安装 Python: forge init tools"; return 1; }
    (cd "$dest" && python -m pip install --prefix "$dest" .) \
        || { err "speckit 安装失败"; return 1; }
    link_binary "$dest/bin/specify" "specify"
}
