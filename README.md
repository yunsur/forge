# Forge

离线 AI 工作站 — 一个自包含的 AI 开发环境，支持内网迁移。

## 快速开始

```bash
# 1. 检查可用更新
./forge update

# 2. 下载工具包（仅下载）
./forge download

# 3. 安装环境无关工具（解压+链接，无需运行时）
./forge install

# 4. 初始化环境依赖工具+配置（pyenv、python、speckit）
./forge init

# 5. 加载环境
source ~/ai/env.sh

# 6. 检查环境
./forge doctor
```

## 目录结构

```
forge/
├── forge                # CLI 入口
├── shell/
│   ├── env.sh           # 环境变量（source 加载）
│   ├── deploy.sh        # 本地开发部署脚本
│   └── forge/*.sh       # 命令模块
├── registry/            # 工具清单（每个工具一个 .sh）
├── rules/common/        # 通用规则（编码、Git、测试、安全）
├── config/
│   ├── claude/
│   │   ├── CLAUDE.md    # Claude Code 全局指令
│   │   ├── agents/      # Agent 角色定义
│   │   ├── commands/    # Slash commands（/commit, /deploy 等）
│   │   ├── skills/      # 内置 Skills
│   │   └── mcp.json     # MCP 服务器配置
│   ├── env/
│   │   └── sources.md   # 软件源（内网 Nexus）
│   └── project/
│       └── constitution.md # 项目宪法（技术栈+架构规则+质量标准）
├── download/            # 下载缓存与 manifest
│   └── versions.lock    # 已安装版本记录
└── ai/                  # 运行时（gitignore）
    ├── bin/             # 工具符号链接 + deploy.sh
    ├── tools/           # 工具安装目录
    ├── runtimes/        # 运行时（pyenv, python）
    ├── rules/           # 部署后的规则
    ├── config/          # 部署后的配置
    ├── mcp/             # 合并 MCP 暂存
    └── cache/           # 缓存（pip, cargo, npm）
```

## forge 命令

| 命令 | 说明 |
|------|------|
| `forge` | 检查并提示更新 |
| `forge -a` | 检查并更新全部 |
| `forge list` | 显示工具状态 |
| `forge update` | 仅检查可用更新 |
| `forge download [tool...]` | 下载工具到 `download/`（不解压） |
| `forge install [tool...]` | 安装环境无关工具（解压+链接，无需运行时） |
| `forge init [tools\|config\|rules\|skills\|mcp\|bins]` | 初始化环境依赖工具+配置 |
| `forge uninstall <tool>` | 卸载工具 |
| `forge skills install <owner/repo/skill>` | 下载 skill |
| `forge skills list` | 显示已安装 skills |
| `forge mcp install` | 安装 MCP server 包 |
| `forge mcp list` | 显示 MCP server 配置 |
| `forge doctor` | 环境检查 |
| `forge pack [file.tgz]` | 打包整站（含二进制）用于内网迁移 |
| `forge new <name>` | 生成新工具的 manifest 模板 |

## Claude Slash Commands

`forge init` 后自动部署到 `~/.claude/commands/`：

| 命令 | 说明 |
|------|------|
| `/commit "feat(auth): add login"` | 一键提交（lint + test + commit） |
| `/deploy` | 一键本地部署 |
| `/security-scan` | 一键安全扫描 |

## Rules

通用规则，`forge init rules` 后部署到 `ai/rules/`：

| 文件 | 内容 |
|------|------|
| `coding-style.md` | 编码规范（命名、结构、注释、错误处理） |
| `git-workflow.md` | Git 工作流（分支、提交格式、PR 规范） |
| `testing.md` | 测试要求（TDD、覆盖率、测试组织） |
| `security.md` | 安全基线（输入校验、认证、依赖审计） |

## 工具清单

### 环境无关（`forge install`）

| 工具 | 说明 |
|------|------|
| rg (ripgrep) | 快速搜索 |
| fd | 文件查找 |
| fzf | 模糊搜索 |
| jq / yq | JSON/YAML 处理 |
| bat | 语法高亮 cat |
| eza | 现代 ls |
| delta | git diff 增强 |
| lazygit | git TUI |
| ast-grep (sg) | AST 搜索 |
| just | 任务运行器 |
| uv | Python 包管理器 |
| node / npm / npx | Node.js |
| go | Go 工具链 |
| rust / cargo | Rust 工具链 |
| claude | Claude Code CLI |
| cc-switch-cli | Claude Code 配置切换 |
| codex | OpenAI Codex CLI |
| starship | 跨 shell 提示符 |
| bun | JavaScript 运行时 |
| pyenv | Python 版本管理（源码脚本） |
| jetbrains-mono-nf | JetBrains Mono Nerd Font |
| superpowers | AI 开发最佳实践（4 skills） |

### 环境依赖（`forge init`，需要 pyenv/uv）

| 工具 | 依赖 | 说明 |
|------|------|------|
| pyenv-virtualenv | pyenv | pyenv 虚拟环境插件 |
| python | pyenv | CPython 源码缓存 |
| speckit | pyenv python | GitHub Spec Kit（spec-driven development） |

## 代理配置

编辑 `shell/env.sh` 取消注释对应的代理行：

```bash
export HTTP_PROXY="http://127.0.0.1:7890"
export HTTPS_PROXY="http://127.0.0.1:7890"
```

## 软件源

内网 Nexus 源，配置在 `config/env/sources.md`：

- pip/uv: `http://172.21.3.9:8081/repository/PyPI_group/simple`
- npm/pnpm: `http://172.21.3.9:8081/repository/npm_group`
- go: `http://172.21.3.9:8081/repository/golang_group,direct`
- cargo: `http://172.21.3.13:8081/repository/cargo_group/`

## 内网迁移

```bash
# 有网机器：打包
./forge pack              # 含二进制（~500MB）

# 传输到内网
scp forge-*.tgz target:~/

# 内网机器：解压
tar xzf forge-*.tgz
cd forge
source ~/ai/env.sh
```

## AI 开发工具

### Superpowers（开发质量保障）

| 类别 | Skills |
|------|--------|
| 测试驱动开发 | test-driven-development |
| 系统化调试 | systematic-debugging |
| 完成前验证 | verification-before-completion |
| 工程代码审查 | requesting-code-review |

```bash
forge download superpowers
forge install
forge init skills
```

### SpecKit（规划工具）

为比赛工作流提供 需求拆解 → plan → tasks 规划能力：

```bash
forge download speckit
forge init tools
```

### Security Review（安全审查）

内置安全审查技能，`forge init skills` 后自动部署：

```bash
forge init skills
```

## 比赛工作流

### 阶段一：比赛（开发）

4 角色闭环 + Superpowers 工程纪律，确保不跑偏。

| 角色 | 职责 | 工具 |
|------|------|------|
| **architect** | 需求拆解 → specify plan → tasks（锚点文档） | `specify plan`, `specify tasks` |
| **scaffold** | 构建项目骨架 | `web-react-cli`, framework CLIs |
| **developer** | TDD 实现任务，一人一分支 feat/task-{id} | `superpowers:test-driven-development` |
| **tester** | 每完成一个 task 立即验证 | `superpowers:verification-before-completion` |

```
architect: 需求拆解 → specify plan + tasks（带 #id + P0/P1/P2）
    ↓
🔵 用户对照原始需求逐项确认 plan
    ↓ 确认通过
scaffold: 搭建骨架 → 向用户确认 → push main → 分配任务
    ↓
developer: 并行 TDD 开发（独立分支 feat/task-{id}）
    ↓
tester: 逐 task 即时验证
    ↓
MVP Checkpoint: P0 完成 → 冻结范围 → 准备 demo
```

### 阶段二：赛后（验证）

| 角色 | 职责 |
|------|------|
| **security** | 安全漏洞测试（依赖审计、注入、权限） |
| **cross-tester** | 黑盒交叉测试（边界、集成、回归） |

```
security + cross-tester + auto-test → 汇总
    │
    ├─ 无问题 → 发布
    └─ 有问题 → 修复 → 重测
```

### 比赛准备

比赛开始后填写：

```bash
# 1. 填写技术栈
$EDITOR config/project/constitution.md

# 2. 重新部署配置
forge init config
```

## Skills

从 [skills.sh](https://skills.sh) 下载 Agent Skills：

```bash
# 单个 skill
forge skills install anthropics/skills/frontend-design

# 整个仓库
forge skills install obra/superpowers
```

## MCP 配置

MCP Server 配置在 `config/claude/mcp.json`，通过 `forge init mcp` 合并到 `~/.claude/mcp.json`。

```bash
$EDITOR config/claude/mcp.json
forge init mcp
forge mcp list
```
