#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# AI 工作站环境
# 用法: source ~/ai/env.sh
# ─────────────────────────────────────────────────────────

_forge_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_HOME="$_forge_root/ai"
RUNTIMES="$AI_HOME/runtimes"

# 注意：配置文件、skills、MCP 的部署由 init.sh 完成
# env.sh 仅负责环境变量设置，不执行任何文件操作

# ── 代理（按实际地址取消注释）───────────────────────────
# export HTTP_PROXY="http://127.0.0.1:7890"
# export HTTPS_PROXY="http://127.0.0.1:7890"
# export ALL_PROXY="socks5://127.0.0.1:7890"
# export NO_PROXY="localhost,127.0.0.1"

# ── pyenv ────────────────────────────────────────────────
export PYENV_ROOT="$RUNTIMES/pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
    PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    pyenv commands -q virtualenv-init 2>/dev/null && eval "$(pyenv virtualenv-init -)"
fi

# ── Go ───────────────────────────────────────────────────
if command -v go &>/dev/null; then
    export GOPATH="$AI_HOME/cache/go"
    export GOPROXY="https://goproxy.cn,direct"
fi

# ── Rust ─────────────────────────────────────────────────
if command -v cargo &>/dev/null; then
    export CARGO_HOME="$AI_HOME/cache/cargo"
    export RUSTUP_HOME="$AI_HOME/cache/rustup"
    export RUSTUP_DIST_SERVER="https://rsproxy.cn"
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    export CARGO_REGISTRIES_CRATES_IO_PROTOCOL="sparse"
    export CARGO_REGISTRIES_CRATES_IO_INDEX="sparse+http://172.21.3.13:8081/repository/cargo_group/"
    [ -d "$CARGO_HOME/bin" ] && PATH="$CARGO_HOME/bin:$PATH"
fi

# ── 工具二进制（最高优先级，覆盖 pyenv shims）────────
[ -d "$AI_HOME/bin" ] && PATH="$AI_HOME/bin:$PATH"

# ── 导出 ─────────────────────────────────────────────────
export PATH
export AI_HOME
export TMPDIR="$AI_HOME/tmp"
export LD_LIBRARY_PATH

# ── PyPI ─────────────────────────────────────────────────
export PIP_CACHE_DIR="$AI_HOME/cache/pip"
export UV_CACHE_DIR="$AI_HOME/cache/uv"
export PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/"
export PIP_TRUSTED_HOST="mirrors.aliyun.com"

# ── Node.js ──────────────────────────────────────────────
if command -v node &>/dev/null; then
    _node_real="$(cd "$(dirname "$(readlink -f "$(command -v node)" || command -v node)")/.." && pwd)"
    [ -d "$_node_real/lib/node_modules" ] && export NODE_PATH="$_node_real/lib/node_modules"
    unset _node_real
    export NPM_CONFIG_REGISTRY="https://registry.npmmirror.com"
fi

# ── OpenSpec ──────────────────────────────────────────────
export OPENSPEC_TELEMETRY=0
export DO_NOT_TRACK=1

# ── 内网源（按实际地址覆盖上面的默认值）────────────────
# export PIP_INDEX_URL="http://172.21.3.9:8081/repository/PyPI_group/simple"
# export PIP_TRUSTED_HOST="172.21.3.9"
# export NPM_CONFIG_REGISTRY="http://172.21.3.9:8081/repository/npm_group"
# export GOPROXY="http://172.21.3.9:8081/repository/golang_group,direct"

# ── git + delta ──────────────────────────────────────────
if command -v delta &>/dev/null; then
    export GIT_PAGER="delta"
    export DELTA_FEATURES="line-numbers side-by-side"
fi

# ── fzf ──────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    command -v fd &>/dev/null && export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    alias preview="fzf --preview 'bat --color=always {}'"
fi

# ── bat ──────────────────────────────────────────────────
if command -v bat &>/dev/null; then
    export BAT_THEME="ansi"
    alias cat="bat --paging=never"
fi

# ── eza ──────────────────────────────────────────────────
if command -v eza &>/dev/null; then
    alias ls="eza --icons"
    alias ll="eza -la --icons --git"
    alias tree="eza --tree --icons --level=3"
fi

# ── 快速导航 ─────────────────────────────────────────────
alias ai="cd $AI_HOME"
alias forgework="cd $_forge_root"
alias ..="cd .."
alias ...="cd ../.."

# ── git ──────────────────────────────────────────────────
alias g="git"
alias gs="git status -sb"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline -20"
alias gp="git pull --rebase"
alias gc="git commit"
alias gco="git checkout"
alias gb="git branch -a"

# 快速搜索文件内容
ff() { rg --color=always "$@" 2>/dev/null || grep -rn "$@" .; }

# 创建目录并进入
mkcd() { mkdir -p "$1" && cd "$1"; }

# 查看环境变量
envs() { env | grep -i "${1:-}" | sort; }

unset _forge_root
