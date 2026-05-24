#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# 自定义别名与函数（env.sh 自动加载）
# ─────────────────────────────────────────────────────────

# ── 快速导航 ─────────────────────────────────────────────
alias ai="cd $AI_HOME"
alias forge="cd $(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# ── forge ────────────────────────────────────────────────
alias fl="forge list"
alias fi="forge install"
alias fu="forge upgrade"
alias fp="forge pack"
alias fs="forge skills"

# ── 开发 ─────────────────────────────────────────────────
alias ll="eza -la --icons --git 2>/dev/null || ls -la"
alias ls="eza --icons 2>/dev/null || ls"
alias tree="eza --tree --icons --level=3 2>/dev/null || find . -maxdepth 3 -type f | head -50"
alias cat="bat --paging=never 2>/dev/null || cat"
alias preview="fzf --preview 'bat --color=always {}'"

# ── 网络诊断 ─────────────────────────────────────────────
alias myip="curl -s ifconfig.me"
alias ports="lsof -i -P -n | grep LISTEN"

# ── 函数 ─────────────────────────────────────────────────

# 快速搜索文件内容
ff() { rg --color=always "$@" 2>/dev/null || grep -rn "$@" .; }

# 创建目录并进入
mkcd() { mkdir -p "$1" && cd "$1"; }

# 查看环境变量
envs() { env | grep -i "${1:-}" | sort; }

# 检查端口占用
port() { lsof -i :"$1" 2>/dev/null || ss -tlnp 2>/dev/null | grep ":$1"; }
