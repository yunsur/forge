#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ForgeStack 团队配置脚本
# 用法: source scripts/team-setup.sh
#
# 环境变量（执行前设置）:
#   GBRAIN_SERVER    GBrain 服务器地址 (如 http://192.168.1.100:3131)
#   GBRAIN_TOKEN     GBrain 访问 token（可选）
#   GITLAB_URL       内部 GitLab 地址 (如 http://gitlab.internal)
#   TEAM_GROUP       GitLab 团组名 (如 forgestack-team)
# ─────────────────────────────────────────────────────────

set -euo pipefail

FORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_HOME="${AI_HOME:-$FORGE_ROOT/ai}"

# ── 颜色 ─────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m'
NC='\033[0m' BOLD='\033[1m'

_log()  { echo -e "${B}[$1]${NC} $2"; }
ok()    { echo -e "${G}[完成]${NC} $1"; }
warn()  { echo -e "${Y}[注意]${NC} $1" >&2; }
err()   { echo -e "${R}[错误]${NC} $1" >&2; }

# ── 1. GBrain 服务器连接 ──────────────────────────────────

setup_gbrain_client() {
    local server="${GBRAIN_SERVER:-}"
    local token="${GBRAIN_TOKEN:-}"

    if [ -z "$server" ]; then
        echo ""
        echo -e "${BOLD}GBrain 团队知识库连接${NC}"
        echo ""
        read -r -p "GBrain 服务器地址 (如 http://192.168.1.100:3131): " server < /dev/tty
        [ -z "$server" ] && { err "未输入服务器地址"; return 1; }
    fi

    # 去掉末尾斜杠
    server="${server%/}"
    local mcp_url="${server}/mcp"

    echo -e "${B}[测试]${NC} 连接 $mcp_url ..."
    if curl -sI --connect-timeout 5 "$mcp_url" &>/dev/null; then
        ok "服务器可达"
    else
        warn "服务器不可达，请确认地址和端口"
        echo "  提示: 服务器端需要运行: gbrain serve --port 3131 --host 0.0.0.0"
    fi

    # 注册 MCP
    local cmd="claude mcp add --scope user --transport http gbrain \"$mcp_url\""
    if [ -n "$token" ]; then
        cmd="$cmd --header \"Authorization: Bearer $token\""
    fi

    echo -e "${B}[配置]${NC} 注册 GBrain MCP ..."
    claude mcp remove gbrain -s user 2>/dev/null || true
    claude mcp remove gbrain 2>/dev/null || true

    if [ -n "$token" ]; then
        claude mcp add --scope user --transport http gbrain "$mcp_url" \
            --header "Authorization: Bearer $token" 2>&1
    else
        claude mcp add --scope user --transport http gbrain "$mcp_url" 2>&1
    fi

    ok "GBrain MCP 已注册"
    echo ""
    echo "  验证: claude mcp list | grep gbrain"
    echo "  使用: 重启 Claude Code 后可用 mcp__gbrain__* 工具"
}

# ── 2. OpenSpec GitLab 仓库配置 ────────────────────────────

setup_openspec_gitlab() {
    local gitlab="${GITLAB_URL:-}"
    local group="${TEAM_GROUP:-}"

    if [ -z "$gitlab" ]; then
        echo ""
        echo -e "${BOLD}OpenSpec 共享仓库配置${NC}"
        echo ""
        read -r -p "GitLab 地址 (如 http://gitlab.internal): " gitlab < /dev/tty
        [ -z "$gitlab" ] && { err "未输入 GitLab 地址"; return 1; }
    fi

    if [ -z "$group" ]; then
        read -r -p "GitLab 团组/项目路径 (如 team/specs): " group < /dev/tty
        [ -z "$group" ] && { err "未输入团组名"; return 1; }
    fi

    gitlab="${gitlab%/}"
    local specs_repo="${gitlab}/${group}.git"

    echo -e "${B}[克隆]${NC} $specs_repo"
    local specs_dir="$AI_HOME/workspaces/specs"
    mkdir -p "$(dirname "$specs_dir")"

    if [ -d "$specs_dir/.git" ]; then
        echo -e "${Y}[已存在]${NC} $specs_dir，执行 git pull ..."
        git -C "$specs_dir" pull --ff-only 2>/dev/null || warn "pull 失败，请手动处理"
    else
        git clone "$specs_repo" "$specs_dir" 2>/dev/null || {
            warn "克隆失败，请确认仓库存在且有权限"
            echo "  创建仓库: 在 GitLab 上创建 ${group} 项目"
            return 1
        }
    fi

    ok "specs 仓库已就绪: $specs_dir"
    echo ""
    echo "  OpenSpec 工作流:"
    echo "    cd $specs_dir"
    echo "    openspec init                  # 初始化项目"
    echo "    /opsx:propose                  # 创建提案（Claude Code 中）"
    echo "    git add . && git commit && git push  # 共享给团队"
}

# ── 3. 团队 CLAUDE.md 生成 ─────────────────────────────────

generate_team_claude_md() {
    local project_dir="${1:-.}"
    local claude_md="$project_dir/CLAUDE.md"

    if [ -f "$claude_md" ]; then
        warn "CLAUDE.md 已存在，跳过"
        return 0
    fi

    cat > "$claude_md" << 'EOF'
# 项目 CLAUDE.md

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate (systematic-debugging)
- QA/testing → invoke /qa or /qa-only
- Code review/diff check → invoke /review or /requesting-code-review
- Ship/deploy/PR → invoke /ship
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Weekly retro → invoke /retro
- TDD → invoke /test-driven-development
- Benchmark → invoke /benchmark

## GBrain

Prefer `gbrain search`/`gbrain query` over Grep for semantic questions.
Use `gbrain code-def`/`code-refs`/`code-callers` for symbol-aware code lookup.

## OpenSpec

Use `/opsx:propose` to create specs. Specs are shared via Git — always pull
before starting new work, push after completing artifacts.

## Team workflow

1. Pull latest: `git pull`
2. Create spec: `/opsx:propose`
3. Implement: `/opsx:apply`
4. Review: `/review` or `/requesting-code-review`
5. Push: `git push`
6. Retro: `/retro`
EOF

    ok "生成 CLAUDE.md: $claude_md"
}

# ── 4. GBrain 服务端初始化（在服务器上运行）─────────────────

setup_gbrain_server() {
    echo ""
    echo -e "${BOLD}GBrain 服务端初始化${NC}"
    echo "  在 GBrain 服务器上运行此命令:"
    echo ""
    echo "  # 1. 安装 gbrain"
    echo "  cd /path/to/forgestack && source env.sh"
    echo ""
    echo "  # 2. 初始化 PGLite"
    echo "  gbrain init --pglite --json"
    echo ""
    echo "  # 3. 启动服务（监听所有网卡）"
    echo "  gbrain serve --port 3131 --host 0.0.0.0"
    echo ""
    echo "  # 4. 设置开机自启（可选）"
    echo "  # 创建 systemd service 或 launchd plist"
    echo ""
    echo "  # 5. 获取服务器 IP"
    echo "  hostname -I | awk '{print \$1}'"
    echo ""
}

# ── 主入口 ────────────────────────────────────────────────

case "${1:-}" in
    gbrain)     setup_gbrain_client ;;
    gitlab)     setup_openspec_gitlab ;;
    claude-md)  generate_team_claude_md "${2:-.}" ;;
    server)     setup_gbrain_server ;;
    all|"")
        echo -e "\n${BOLD}ForgeStack 团队配置${NC}\n"
        echo "用法: source scripts/team-setup.sh <子命令>"
        echo ""
        echo "  gbrain      配置 GBrain 客户端连接"
        echo "  gitlab      配置 OpenSpec GitLab 仓库"
        echo "  claude-md   生成团队 CLAUDE.md"
        echo "  server      显示 GBrain 服务端初始化步骤"
        echo ""
        echo "环境变量:"
        echo "  GBRAIN_SERVER   GBrain 服务器地址"
        echo "  GBRAIN_TOKEN    访问 token（可选）"
        echo "  GITLAB_URL      GitLab 地址"
        echo "  TEAM_GROUP      团组路径"
        echo ""
        echo "示例:"
        echo "  GBRAIN_SERVER=http://192.168.1.100:3131 source scripts/team-setup.sh gbrain"
        echo "  GITLAB_URL=http://gitlab.internal TEAM_GROUP=team/specs source scripts/team-setup.sh gitlab"
        ;;
    *) err "未知子命令: $1"; exit 1 ;;
esac
