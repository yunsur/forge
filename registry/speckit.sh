#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: speckit
# @repo: github/spec-kit

get_latest() { github_latest "github/spec-kit"; }

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    # GitHub tarball URL 需要指定文件名
    export _DOWNLOAD_FILENAME="spec-kit-${latest}.tar.gz"
    fetch "speckit" \
        "https://api.github.com/repos/github/spec-kit/tarball/${latest}" \
        "tar.gz" "strip1"
    unset _DOWNLOAD_FILENAME
    # 注意：install_from() 在 forge init 时调用，此处不安装
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

    # 查找可用的 Python（优先 pyenv）
    local python_cmd=""
    local pyenv_root="$RUNTIMES_DIR/pyenv"
    if [ -x "$pyenv_root/bin/pyenv" ]; then
        export PYENV_ROOT="$pyenv_root"
        export PATH="$pyenv_root/bin:$PATH"
        python_cmd="$pyenv_root/bin/pyenv exec python"
    elif command -v python3 &>/dev/null; then
        python_cmd="python3"
    elif command -v python &>/dev/null; then
        python_cmd="python"
    else
        err "需要先安装 Python: forge init tools"
        return 1
    fi

    # 加载 env.sh 获取 PyPI 源配置
    local env_sh="$SCRIPT_DIR/../shell/env.sh"
    if [ -f "$env_sh" ]; then
        # 仅导出最后出现的 PIP 相关变量（内网源会覆盖公网源）
        export PIP_INDEX_URL=$(grep -E '^export PIP_INDEX_URL=' "$env_sh" | tail -1 | sed 's/^export [^=]*=//')
        export PIP_TRUSTED_HOST=$(grep -E '^export PIP_TRUSTED_HOST=' "$env_sh" | tail -1 | sed 's/^export [^=]*=//')
    fi

    # 使用 --target 安装到指定目录
    (cd "$dest" && $python_cmd -m pip install --target "$dest/lib" .) \
        || { err "speckit 安装失败"; return 1; }

    # 创建 bin 目录并重写 specify 脚本
    mkdir -p "$dest/bin"
    local python_bin
    python_bin=$($python_cmd -c "import sys; print(sys.executable)")
    cat > "$dest/bin/specify" << EOF
#!${python_bin}
import sys, os
# 解析 symlink，获取真实路径
_script = os.path.abspath(__file__)
if os.path.islink(_script):
    _script = os.path.realpath(_script)
sys.path.insert(0, os.path.join(os.path.dirname(_script), '..', 'lib'))
from specify_cli import main
if __name__ == '__main__':
    main()
EOF
    chmod +x "$dest/bin/specify"

    link_binary "$dest/bin/specify" "specify"
}
