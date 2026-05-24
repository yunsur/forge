# ForgeStack — AI Agent 指南

## 项目概览

ForgeStack 是一个离线可用的 AI 开发工作站，基于纯 Bash 构建。核心功能是安装、版本管理和打包一套精选的 CLI 工具、AI Agent 技能和 MCP 服务器配置，支持打包为 tarball 部署到内网/离线机器。

## 架构

```
forgestack/
├── forge                  # 主 CLI（~750 行 bash）
├── env.sh                 # 环境加载器（source 到 shell）
├── registry/              # 工具清单脚本（每个 .sh = 一个工具）
├── scripts/
│   ├── _common.sh         # 公共函数库（fetch, link_binary, github_latest）
│   ├── gbrain-server.sh   # GBrain 知识服务器部署
│   └── team-setup.sh      # 团队协作配置
├── skills/                # 15 个 Agent Skills（SKILL.md 驱动）
├── mcp/                   # MCP 服务器配置（JSON，合并到 ~/.claude/mcp.json）
├── config/                # 配置模板（symlink 到 ~/）
├── shell/                 # Shell 别名和辅助函数
└── ai/                    # 运行时目录（gitignored）
    ├── tools/             # 已安装工具目录
    ├── bin/               # 工具二进制 symlink
    ├── versions.lock      # 已安装版本记录（管道分隔）
    └── runtimes/          # pyenv + python
```

## 核心文件

| 文件 | 用途 |
|------|------|
| `forge` | 主 CLI，实现 install/upgrade/uninstall/list/update/pack/export/doctor/new/skills |
| `env.sh` | 环境加载器，配置 PATH、镜像源、symlink 配置文件、合并 MCP JSON |
| `scripts/_common.sh` | 公共函数：`github_latest()`, `fetch()`, `fetch_to()`, `link_binary()`, `_curl_opts()` |
| `ai/versions.lock` | 版本锁定文件，格式：`工具名|版本|日期` |

## Registry Manifest 规范

每个 `registry/*.sh` 文件是一个工具清单，必须包含：

```bash
#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../scripts/_common.sh"

# @name: 工具名
# @repo: GitHub 仓库（owner/repo）

get_latest() {
    # 返回最新版本号（字符串）
    github_latest "owner/repo"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }

    # 1. 下载并解压到 $TOOLS_DIR/工具名/
    fetch "工具名" "下载URL" "格式(tar.gz|zip|binary)" "strip层级"

    # 2. 创建 symlink 到 $AI_HOME/bin/
    link_binary "$TOOLS_DIR/工具名/可执行文件名"
}
```

### 添加新工具

1. `forge new <工具名>` — 生成 manifest 模板
2. 编辑 `registry/<工具名>.sh`，实现 `get_latest()` 和 `upgrade()`
3. `forge install <工具名>` — 安装并验证

### 常用公共函数

- `github_latest "owner/repo"` — 从 GitHub API 获取最新 release tag
- `fetch "名" "URL" "格式" "strip"` — 下载并解压到 `$TOOLS_DIR/名/`
- `fetch_to "目标文件" "URL"` — 下载单个文件到指定路径
- `link_binary "源路径"` — 创建 symlink 到 `$AI_HOME/bin/`
- `_curl_opts` — 返回 curl 选项（自动处理代理和 GITHUB_TOKEN）

## Forge CLI 命令

| 命令 | 用途 |
|------|------|
| `forge` | 交互式检查并提示更新（类似 brew cu） |
| `forge -a` | 检查并更新全部工具 |
| `forge install [tool]` | 安装全部或指定工具 |
| `forge upgrade [tool]` | 更新全部或指定工具 |
| `forge uninstall <tool>` | 卸载指定工具 |
| `forge list` | 显示所有工具状态 |
| `forge update` | 仅检查可用更新 |
| `forge pack` | 打包 tarball（含二进制，用于离线传输） |
| `forge export` | 导出配置 tarball（不含二进制） |
| `forge doctor` | 环境健康检查 |
| `forge new <name>` | 生成新工具 manifest 模板 |
| `forge skills install/list/remove` | 管理 Agent Skills（从 GitHub sparse checkout） |

## 环境变量

| 变量 | 用途 |
|------|------|
| `GITHUB_TOKEN` | GitHub API token（避免限速） |
| `https_proxy` / `HTTPS_PROXY` | HTTPS 代理 |
| `AI_HOME` | 工具安装根目录（默认 `$ROOT/ai`） |
| `OS` / `ARCH` | 目标平台（默认 linux/amd64） |

## Skills 结构

每个 skill 是 `skills/` 下的一个目录，包含 `SKILL.md`：

```
skills/
├── brainstorming/SKILL.md
├── writing-plans/SKILL.md
├── executing-plans/SKILL.md
├── test-driven-development/SKILL.md
├── systematic-debugging/SKILL.md
├── requesting-code-review/SKILL.md
├── receiving-code-review/SKILL.md
├── verification-before-completion/SKILL.md
├── dispatching-parallel-agents/SKILL.md
├── subagent-driven-development/SKILL.md
├── finishing-a-development-branch/SKILL.md
├── using-git-worktrees/SKILL.md
├── frontend-design/SKILL.md
├── writing-skills/SKILL.md
└── using-superpowers/SKILL.md
```

Skills 通过 `forge skills install` 从 GitHub 仓库 sparse checkout 安装，安装后 symlink 到 `~/.claude/skills/`。

## MCP 配置

`mcp/*.json` 文件在 `env.sh` source 时自动合并到 `~/.claude/mcp.json`：

- `context7.json` — 文档查询（Upstash Context7）
- `filesystem.json` — 文件系统访问（作用域：`$HOME/projects`）
- `github.json` — GitHub 操作（需配置 personal access token）

## 开发约定

1. **纯 Bash** — 项目不使用 Python/JS 源码，仅 shell 脚本
2. **set -euo pipefail** — 所有脚本严格模式
3. **中文输出** — 用户界面消息使用中文
4. **离线优先** — 所有工具必须可打包离线部署
5. **版本锁定** — 安装版本记录在 `ai/versions.lock`，格式 `工具名|版本|日期`
6. **Symlink 管理** — 工具二进制通过 symlink 链接到 `ai/bin/`，配置文件 symlink 到 `~/`

## 验证方式

```bash
# 环境健康检查
forge doctor

# 查看工具状态
forge list

# 检查版本锁定
cat ai/versions.lock

# 测试单个 manifest
source registry/<tool>.sh && get_latest
```
