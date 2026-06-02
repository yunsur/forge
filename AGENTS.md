# Forge — AI Agent 指南

## 项目概览

Forge 是一个离线可用的 AI 开发工作站，基于纯 Bash 构建。核心功能是版本管理和打包一套精选的 CLI 工具、AI Agent 技能和 MCP 服务器配置，支持打包为 tarball 部署到内网/离线机器。

## 架构

```
forge/
├── forge                  # CLI 入口（薄脚本，~40 行）
├── shell/
│   ├── env.sh             # 运行时环境加载器（source 到 shell）
│   └── forge/
│       ├── common.sh      # 公共函数库 + forge 共享函数
│       ├── check.sh       # update 命令（检查更新 + 缓存版本）
│       ├── download.sh    # download 命令（只下载不解压）
│       ├── install.sh     # install 命令（安装环境无关工具）
│       ├── init.sh        # init 命令（环境依赖工具+配置）
│       ├── list.sh        # list 命令（3 列显示）
│       ├── pack.sh        # pack 命令（打包整站）
│       ├── uninstall.sh   # uninstall 命令
│       ├── new.sh         # new 命令（生成 manifest 模板）
│       ├── doctor.sh      # doctor 命令（环境检查）
│       ├── skills.sh      # skills 管理
│       ├── mcp.sh         # mcp 命令（安装/列出 MCP server）
│       └── help.sh        # 帮助信息
├── registry/              # 工具清单脚本（每个 .sh = 一个工具）
├── config/
│   ├── claude/
│   │   ├── CLAUDE.md      # Claude Code 全局指令（forge-lite 工作流）
│   │   ├── agents/        # Agent 角色定义（symlink 到 ~/.claude/agents/）
│   │   └── mcp.json       # MCP 服务器配置（合并到 ~/.claude/mcp.json）
│   └── openspec/          # OpenSpec 配置（symlink 到 ~/.config/openspec/）
├── download/              # 下载缓存
│   ├── download.manifest  # 下载记录：name|version|filename
│   └── update.manifest    # 最新版本缓存：name|version
├── versions.lock          # 已安装版本记录：name|version|date
└── ai/                    # 运行时目录（gitignored）
    ├── tools/             # 已安装工具目录
    ├── bin/               # 工具二进制 symlink
    ├── mcp/               # 合并后的 MCP JSON 暂存
    └── runtimes/          # pyenv + python
```

## 核心文件

| 文件 | 用途 |
|------|------|
| `forge` | CLI 入口，source `shell/forge/*.sh` 模块，case 分发命令 |
| `shell/forge/common.sh` | 公共函数：`fetch()`, `link_binary()`, `github_latest()`, `_dw()`, `_pad()`, 注册表加载 |
| `shell/forge/install.sh` | install 命令：安装环境无关工具（解压+git clone+字体+链接），跳过 env-dep 工具 |
| `shell/forge/mcp.sh` | MCP 管理：`mcp install` 安装包，`mcp list` 列出已配置 server |
| `shell/env.sh` | 运行时环境，配置 PATH、镜像源、symlink 配置、合并 MCP JSON |
| `config/claude/CLAUDE.md` | Claude Code 全局指令，定义 forge-lite 工作流 |
| `config/claude/agents/*.md` | Agent 角色定义（architect, backend, frontend, security, tech-lead, tester） |
| `config/claude/mcp.json` | MCP 服务器配置，init 时合并到 `~/.claude/mcp.json` |
| `versions.lock` | 版本锁定文件，格式：`name|version|date` |
| `download/update.manifest` | 最新版本缓存，由 `forge update` 写入 |

## Forge 入口

`forge` 是薄脚本，source 所有 `shell/forge/*.sh` 模块后 case 分发：

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
for f in "$ROOT_DIR/shell/forge"/*.sh; do
    [ -f "$f" ] || continue
    source "$f"
done
case "${1:-}" in
    -a|--all)       cmd_check "true" ;;
    download)       shift; cmd_download "$@" ;;
    install)        shift; cmd_install "$@" ;;
    init)           shift; cmd_init "$@" ;;
    uninstall|rm)   shift; cmd_uninstall "$@" ;;
    list|ls)        cmd_list ;;
    update)         cmd_check "false" ;;
    new)            shift; cmd_new "$@" ;;
    pack)           shift; cmd_pack "$@" ;;
    push)           shift; cmd_push "$@" ;;
    skills)         shift; cmd_skills "$@" ;;
    mcp)            shift; cmd_mcp "$@" ;;
    doctor)         cmd_doctor ;;
    help|--help|-h) show_help ;;
    "")             cmd_check "false" ;;
    *)              show_help; exit 1 ;;
esac
```

## Registry Manifest 规范

每个 `registry/*.sh` 文件是一个工具清单，必须包含：

```bash
#!/usr/bin/env bash
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../shell/forge/common.sh"

# @name: 工具名
# @repo: GitHub 仓库（owner/repo）

get_latest() {
    github_latest "owner/repo"
}

upgrade() {
    local latest; latest=$(get_latest)
    [ -z "$latest" ] && { err "无法获取最新版本"; exit 1; }

    fetch "工具名" "下载URL" "格式(tar.gz|zip|binary)" "strip层级"
    link_binary "$TOOLS_DIR/工具名/可执行文件名"
}

install_from() {
    local file="$1"
    install_from_file "$file" "工具名" "格式" "mode" "binary_name"
}
```

### 两阶段安装

- **`forge install`** — 调用 `install_from()`，处理环境无关工具（跳过 `ENV_DEPS_TOOLS` 列表中的工具）
- **`forge init`** — 调用 `install_from()`，仅处理环境依赖工具（pyenv-virtualenv、python、openspec、speckit）+ 配置/skills/mcp/bins

### 添加新工具

1. `forge new <工具名>` — 生成 manifest 模板
2. 编辑 `registry/<工具名>.sh`，实现 `get_latest()`、`upgrade()` 和 `install_from()`
3. `forge download` — 下载到 `download/`
4. `forge install` — 安装环境无关工具 / `forge init` — 安装环境依赖工具

### 常用公共函数（shell/forge/common.sh）

- `github_latest "owner/repo"` — 从 GitHub API 获取最新 release tag
- `fetch "名" "URL" "格式" "mode"` — 下载并解压到 `$TOOLS_DIR/名/`
- `fetch_to "目标目录" "URL" "格式" "mode"` — 下载解压到指定目录
- `link_binary "源路径"` — 创建 symlink 到 `$AI_HOME/bin/`
- `download_only "名" "URL"` — 只下载不解压到 `download/`
- `_curl_opts` — 返回 curl 选项（自动处理代理和 GITHUB_TOKEN）

## Forge CLI 命令

| 命令 | 用途 |
|------|------|
| `forge` | 检查并提示更新（类似 brew cu） |
| `forge -a` | 检查并更新全部工具 |
| `forge update` | 仅检查可用更新（缓存到 update.manifest） |
| `forge download` | 只下载不解压（保存到 download/） |
| `forge install [tool...]` | 安装环境无关工具（解压+链接，无需运行时） |
| `forge init [tools|config|skills|mcp|bins]` | 初始化环境依赖工具+配置 |
| `forge uninstall <tool>` | 卸载指定工具 |
| `forge list` | 显示所有注册工具状态（3 列） |
| `forge pack [file.tgz]` | 打包整站用于内网迁移 |
| `forge push <user@host[:port]>` | 打包并 scp 到远程服务器 |
| `forge doctor` | 环境健康检查 |
| `forge new <name>` | 生成新工具 manifest 模板 |
| `forge skills install/list/remove` | 管理 Agent Skills |
| `forge mcp install` | 安装 MCP server 包 |
| `forge mcp remove <name>` | 从配置中移除 MCP server |
| `forge mcp list` | 列出已配置的 MCP server |

### 工作流

```
forge update     # 检查最新版本，缓存到 download/update.manifest
forge download   # 下载所有工具到 download/
forge install    # 安装环境无关工具（解压+链接）
forge init       # 安装环境依赖工具+配置+skills+mcp+bins
```

## list 命令显示

3 列对齐显示（CJK 字符宽度感知）：

| 列 | 内容 | 说明 |
|----|------|------|
| 工具名称 | registry 中所有工具 | 始终显示 |
| 当前版本 | 已下载/已安装的版本 | 未下载显示 `-` |
| 最新版本 | update.manifest 缓存 | 未检查显示 `-` |

对齐使用 `_dw()` 计算显示宽度（CJK=2, ASCII=1），`_pad()` 按显示宽度填充空格。

## 下载清单格式

- `download/download.manifest` — `name|version|filename`（如 `rg|15.1.0|rg-15.1.0-aarch64-apple-darwin.tar.gz`）
- `download/update.manifest` — `name|version`（如 `ast-grep|0.43.0`，由 `forge update` 写入）

## 环境变量

| 变量 | 用途 |
|------|------|
| `GITHUB_TOKEN` | GitHub API token（避免限速） |
| `https_proxy` / `HTTPS_PROXY` | HTTPS 代理 |
| `AI_HOME` | 工具安装根目录（默认 `$ROOT/ai`） |
| `OS` / `ARCH` | 目标平台（默认 linux/amd64） |

## 开发约定

1. **纯 Bash** — 项目不使用 Python/JS 源码，仅 shell 脚本
2. **set -euo pipefail** — 所有脚本严格模式
3. **macOS bash 3.2 兼容** — 不使用 `declare -A`（关联数组），用 case 语句替代
4. **中文输出** — 用户界面消息使用中文
5. **离线优先** — 所有工具必须可打包离线部署
6. **版本锁定** — 安装版本记录在 `versions.lock`，格式 `name|version|date`
7. **Symlink 管理** — 工具二进制通过 symlink 链接到 `ai/bin/`，配置文件 symlink 到 `~/`
8. **函数覆盖** — `forge download` 在子 shell 中覆盖 `fetch()`/`fetch_to()`/`link_binary()` 实现只下载
9. **两阶段安装** — `forge install` 处理环境无关工具（24 个），`forge init` 处理环境依赖工具（4 个：pyenv-virtualenv、python、openspec、speckit）+ 配置

## 验证方式

```bash
# 环境健康检查
forge doctor

# 查看工具状态
forge list

# 检查版本锁定
cat versions.lock

# 测试单个 manifest
source registry/<tool>.sh && get_latest
```
