#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: superpowers
# @repo: obra/superpowers

# 选中的 skills
SUPERPOWERS_SKILLS=(
    # Code review
    requesting-code-review receiving-code-review
    # Testing
    test-driven-development
    # Safety
    verification-before-completion systematic-debugging
)

get_latest() {
    github_latest "obra/superpowers"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }
    _log "下载" "Superpowers ${latest}"
    local dest="$TOOLS_DIR/superpowers"
    rm -rf "$dest"
    git clone --depth 1 --single-branch \
        "https://github.com/obra/superpowers.git" "$dest" 2>/dev/null

    # 选择性链接 skills
    mkdir -p "$HOME/.claude/skills"
    local linked=0
    for skill in "${SUPERPOWERS_SKILLS[@]}"; do
        if [ -d "$dest/skills/$skill" ]; then
            ln -sfn "$dest/skills/$skill" "$HOME/.claude/skills/sp-${skill}"
            ((linked++)) || true
        fi
    done
    ok "superpowers $latest (${linked}/${#SUPERPOWERS_SKILLS[@]} skills)"
}
