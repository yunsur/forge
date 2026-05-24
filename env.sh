#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# AI 工作站环境
# 用法: source ~/ai/env.sh
# ─────────────────────────────────────────────────────────

AI_HOME="$HOME/ai"
RUNTIMES="$AI_HOME/runtimes"

# ── 开发模式：从项目目录同步到 ai/ ──────────────────────
_forge_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$_forge_root/config" ] && [ "$_forge_root" != "$AI_HOME" ]; then
    mkdir -p "$AI_HOME/config"
    [ -d "$_forge_root/config/claude" ] && cp -r "$_forge_root/config/claude" "$AI_HOME/config/" 2>/dev/null
    [ -d "$_forge_root/config/codex" ] && cp -r "$_forge_root/config/codex" "$AI_HOME/config/" 2>/dev/null
    [ -d "$_forge_root/skills" ] && ln -sfn "$_forge_root/skills" "$AI_HOME/skills"
    [ -d "$_forge_root/mcp" ] && ln -sfn "$_forge_root/mcp" "$AI_HOME/mcp"
fi
unset _forge_root

# ── 配置文件链接：ai/config/ → ~/.xxx/ ──────────────────
# Claude Code: ai/config/claude/setting.json → ~/.claude/setting.json
if [ -d "$AI_HOME/config/claude" ]; then
    mkdir -p "$HOME/.claude"
    for f in "$AI_HOME/config/claude"/*; do
        [ -f "$f" ] && ln -sfn "$f" "$HOME/.claude/$(basename "$f")"
    done
fi
# Codex: ai/config/codex/* → ~/.codex/*
if [ -d "$AI_HOME/config/codex" ]; then
    mkdir -p "$HOME/.codex"
    for f in "$AI_HOME/config/codex"/*; do
        [ -f "$f" ] && ln -sfn "$f" "$HOME/.codex/$(basename "$f")"
    done
fi
# Skills: ai/skills/* → ~/.claude/skills/*
if [ -d "$AI_HOME/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    for d in "$AI_HOME/skills"/*/; do
        [ -d "$d" ] && ln -sfn "$d" "$HOME/.claude/skills/$(basename "$d")"
    done
fi
# MCP: ai/mcp/*.json → ~/.claude/mcp.json（合并所有 MCP 配置）
if [ -d "$AI_HOME/mcp" ]; then
    mkdir -p "$HOME/.claude"
    python3 -c "
import json,os,glob
base={'mcpServers':{}}
for f in sorted(glob.glob('$AI_HOME/mcp/*.json')):
    with open(f) as fh: d=json.load(fh)
    base['mcpServers'].update(d.get('mcpServers',{}))
with open('$HOME/.claude/mcp.json','w') as fh: json.dump(base,fh,indent=2)
" 2>/dev/null
fi

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
    mkdir -p "$GOPATH"
fi

# ── Rust ─────────────────────────────────────────────────
if command -v cargo &>/dev/null; then
    export CARGO_HOME="$AI_HOME/cache/cargo"
    export RUSTUP_HOME="$AI_HOME/cache/rustup"
    export RUSTUP_DIST_SERVER="https://rsproxy.cn"
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    export RUSTUP_REGISTRY_DEFAULT="rsproxy-sparse"
    [ -d "$CARGO_HOME/bin" ] && PATH="$CARGO_HOME/bin:$PATH"
fi

# ── CUDA（可选）──────────────────────────────────────────
if [ -d "$AI_HOME/cuda" ]; then
    export CUDA_HOME="$AI_HOME/cuda"
    PATH="$CUDA_HOME/bin:$PATH"
    LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
fi

# ── 工具二进制 ───────────────────────────────────────────
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
# export PIP_INDEX_URL="https://your-internal-pypi/simple"
# export PIP_TRUSTED_HOST="your-internal-pypi"
# export NPM_CONFIG_REGISTRY="https://your-internal-npm"
# export GOPROXY="https://your-internal-goproxy,direct"

# ── git + delta ──────────────────────────────────────────
if command -v delta &>/dev/null; then
    export GIT_PAGER="delta"
    export DELTA_FEATURES="line-numbers side-by-side"
fi

# ── fzf ──────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    command -v fd &>/dev/null && export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
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
    alias tree="eza --tree --icons"
fi

# ── 自定义脚本 bin/ + shell 配置 ─────────────────────────
_forge_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$_forge_root/bin" ]; then
    for f in "$_forge_root/bin"/*; do
        [ -f "$f" ] && [ ! -L "$AI_HOME/bin/$(basename "$f")" ] && \
            ln -sf "$f" "$AI_HOME/bin/$(basename "$f")"
    done
fi
for f in "$_forge_root/shell"/*.sh; do
    [ -f "$f" ] && source "$f"
done
unset _forge_root
