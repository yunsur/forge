# 3 人团队协作指南

---

## 架构概览

### 三种模式

| 模式 | 触发词 | 用途 |
|------|--------|------|
| **比赛模式** | `比赛模式` / `competition mode` | 完整 3 角色闭环 |
| **赛后验证** | `赛后验证` / `verification mode` | 安全 + 交叉测试 |
| **快速通道** | `fast track` / `直接改` | 跳过规划，直接修 |
| **直接开发** | `直接开发` / `继续开发` | 已有骨架，跳过 architect + scaffold |

### 比赛工作流（核心流程）

```
┌─────────────────────────────────────────────────────────────┐
│  1. ARCHITECT 需求拆解                                        │
│     ├── 分析粗需求，提取核心目标                               │
│     ├── 识别缺失点（数据模型、权限、规模等）                    │
│     ├── 向用户提问确认                                        │
│     └── 输出细化需求文档                                      │
│                         ↓                                   │
│  2. ARCHITECT 规划                                            │
│     ├── 读 tech-stack.md（技术栈约束）                        │
│     ├── speckit plan → plan.md（锚定文档）                    │
│     └── speckit tasks → tasks.md（带 #id + P0/P1/P2 优先级）  │
│                         ↓                                   │
│  3. 🔵 PLAN 人工确认（关键环节）                               │
│     ├── 用户逐项对照原始需求                                  │
│     ├── ✅ 正确 / ❌ 有误 / ➕ 补充 / ➖ 删减                  │
│     └── 未确认前 scaffold/developer 不得动                    │
│                         ↓                                   │
│  4. SCAFFOLD 搭骨架                                          │
│     ├── 后端框架初始化（FastAPI + Python）                    │
│     ├── 前端框架初始化（React + Vite + pnpm）                │
│     ├── shared 代码（类型定义、工具函数、DB schema）            │
│     ├── 基础配置（tsconfig、eslint、env 模板）                 │
│     ├── push to main（骨架可运行）                             │
│     └── 按依赖关系分配任务                                     │
│                         ↓                                   │
│  5. DEVELOPER 并行 TDD 开发                                   │
│     ├── 每人独立分支 feat/task-{id}                           │
│     ├── 1. 读 task + 验收标准                                 │
│     ├── 2. 🔴 写失败测试                                      │
│     ├── 3. 🟢 写最小实现                                      │
│     ├── 4. ♻️ 重构（如需要）                                   │
│     └── 5. ✅ 标记完成                                        │
│                         ↓                                   │
│  6. TESTER 即时验证                                          │
│     ├── Scope Check（范围漂移检测）                           │
│     ├── Functional（测试通过）                                │
│     ├── Plan Alignment（符合 plan 意图）                     │
│     └── Verdict: PASS → 下一个 / FAIL → developer 修复       │
│                         ↓                                   │
│  7. MVP CHECKPOINT                                           │
│     ├── 所有 P0 完成 → 核心链路可演示                          │
│     ├── 是 → 冻结范围，准备 demo                              │
│     └── 否 → 继续补 P0                                       │
│                         ↓                                   │
│  8. 循环 5-7 直到所有 task 完成                               │
│                         ↓                                   │
│  9. /commit 提交                                              │
└─────────────────────────────────────────────────────────────┘
```

### 直接开发模式（跳过 architect + scaffold）

```
触发: "直接开发" / "继续开发"
前提: 骨架已存在，tasks.md 已有带编号任务

  1. Claude 读 tasks.md → 展示任务清单（带 #编号）
  2. 用户选择任务编号（如 4,5,6）
  3. 输出详细设计 → 用户确认 / 调整 / 跳过
  4. developer 逐 task 实现（TDD）
  5. 功能测试通过 → 提 PR
  6. 循环直到所选 task 完成
```

### 赛后验证

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   security   │   │ cross-tester │   │  auto-test   │
│  安全扫描     │   │  黑盒测试     │   │  全量测试     │
└──────────────┘   └──────────────┘   └──────────────┘
       │                  │                  │
       └──────── 汇总 ────┴──────────────────┘
                  │
                  ├─ 无问题 → /deploy
                  └─ 有问题 → 修复 → 重测
```

### Anti-Drift 保障

1. **用户先验证 plan** — architect 产出后人机对照验收
2. **Plan 是锚** — developer 只实现 plan 列出的内容
3. **原子化 task** — 每个 task 可独立验证
4. **3 角色闭环** — architect 规划 → developer 实现 → tester 验证，漂移立即被捕获

---

## 优先级与砍需求

每个 task 必须带优先级标签：

| 优先级 | 含义 | 规则 |
|--------|------|------|
| **P0** | Must-have，MVP 核心 | 必须完成 |
| **P1** | Should-have，重要 | P0 完成后视时间做 |
| **P2** | Nice-to-have，锦上添花 | P0+P1 都完成后才做 |

时间不足时的砍需求策略：

1. P2 全部砍掉
2. 剩余不到 30% 时间，P1 也砍
3. 全力保 P0
4. 所有 developer 集中做 P0

---

## 分支策略

一个 task = 一个分支，绝不例外。

```
main
 ├── feat/task-1   (developer-1)
 ├── feat/task-2   (developer-2)
 └── feat/task-3   (developer-3)
```

规则：
- 分支名：`feat/task-{id}`，`{id}` 来自 tasks 清单
- developer 开发前 checkout 分支，tester 验证后才 merge
- 两个 task 冲突（共享文件）→ architect 重排或拆分 task
- 活跃开发期间禁止直接 commit main

Task ID 格式（从 `speckit tasks` 输出）：

```
- [ ] #1 [P0] 用户注册接口      → feat/task-1
- [ ] #2 [P0] 登录鉴权          → feat/task-2
- [ ] #3 [P1] 任务列表页        → feat/task-3
```

所有角色用 `#{id}` 引用任务 — developer 读 `#1`，tester 验证 `#1`，architect 重分配 `#1`。ID 是流水线中唯一的真值来源。

---

## 并行调度

architect 分配任务时考虑依赖关系：

```
developer-1: task-1, task-4  (independent, parallel)
developer-2: task-2           (independent, parallel)
developer-3: task-3           (blocked by task-2, starts after merge)
```

规则：
- 无依赖任务 → 并行分配给不同 developer
- 有依赖任务 → 等前置 task merge 后再启动
- 不同 developer 不在同一阶段改同一个文件
- developer 提前完成 → architect 从 P1 队列重分配

---

## 异常回退

| 场景 | 处理 |
|------|------|
| 任务超时 (2x 预估) | 标记 blocked，跳过，做下一个 P0 |
| 分支冲突无法解决 | 换人 + 新分支重新做 |
| 所有 P0 被阻塞 | 用户决定：简化范围 or 延长时间 |
| merge 后测试失败 | revert merge，developer 修复后重新提交 |
| 50% 时间无 P0 完成 | 紧急砍范围：只保 1 个核心功能 |

核心原则：**不停流水线**。一个任务阻塞就绕过去，目标是 MVP，不是完美。

---

## 本地联调 & 部署

### Docker Compose 全栈环境

模板文件在 `config/project/docker/`，scaffold 阶段复制到项目根目录。

**启动：**

```bash
docker compose up -d        # 启动 postgres:15 + redis:7 + backend + frontend
docker compose logs -f backend  # 看后端日志
docker compose down -v       # 停掉并清数据（重置用）
```

**增量编译原理：**

```
Dockerfile 分两层:
  第一层: COPY requirements.txt / package.json → pip install / pnpm install
  第二层: COPY . .  (代码)

改代码时只重建第二层，依赖层走缓存 → 启动从 2 分钟降到 5 秒
```

### 3 人并行联调

```
每个人本地: docker compose up -d

第 1 个人 (module-a)          第 2 个人 (module-b)          第 3 个人 (module-c)
├── 改代码 → 容器热重载        ├── 改代码 → 容器热重载        ├── 改代码 → 容器热重载
├── 本地验证 module-a         ├── 本地验证 module-b         ├── 本地验证 module-c
└── push → PR                 └── push → PR                 └── push → PR

合并到 main 后:
├── git pull origin main
├── docker compose restart     ← 拿到最新代码
├── 跑全量测试                 ← 验证模块间联调
└── 通过 → 继续 / 提交
```

### 联调规则

| 规则 | 说明 |
|------|------|
| **本地必须能跑** | 提交前 `docker compose up` 能启动、测试能过 |
| **合并后重启验证** | 合并 main 后重启容器跑全量测试 |
| **API 契约先行** | scaffold 阶段定义 OpenAPI 契约，前后端按契约开发 |
| **DB migration** | schema 变更走 migration 文件，不手动改 DB |
| **环境变量统一** | `.env.example` 提交仓库，`.env` 不提交 |

### 部署

合并 main → 测试通过 → 选一种部署方式：

```bash
# 方案 A: Docker 部署（推荐，需要服务器）
docker compose -f docker-compose.prod.yml up -d --build

# 方案 B: 直接部署（简单项目）
# 传代码 → 装依赖 → 跑测试 → 启服务

# 方案 C: 静态部署（前后端完全分离）
# 前端 build → nginx/CDN，后端单独部署
```

---

## 两种模式

### 模式一：完整流程（新项目 / 复杂任务）

```
architect → scaffold → developer-1/2/3 并行
```

触发词：`比赛模式`、`competition mode`

### 模式二：直接开发（已有骨架 / 小任务 / bug 修复）

```
developer 直接按 tasks 开发（跳过 architect + scaffold）
```

触发词：`直接开发`、`继续开发`、`direct dev`

---

## 角色分工

### 完整流程角色

```
第 1 个人
├── architect: 需求拆解 → plan → tasks
├── scaffold: 搭骨架 → push main → 分配任务
└── 也参与开发（选剩余任务）

第 2 个人                          第 3 个人
├── developer                      ├── developer
│   ├── git pull                   │   ├── git pull
│   ├── checkout feat/task-1       │   ├── checkout feat/task-2
│   ├── 选任务 #1,#2               │   ├── 选任务 #3,#4
│   └── 实现 → 测试 → PR          │   └── 实现 → 测试 → PR
```

| 角色 | 谁操作 | 职责 |
|------|--------|------|
| **第 1 个人** | architect + scaffold + developer | 规划 → 搭骨架 → push → 也参与开发 |
| **第 2 个人** | developer | 拉取 → 选任务 → 实现 → PR |
| **第 3 个人** | developer | 拉取 → 选任务 → 实现 → PR |

### 直接开发角色

```
Claude 实例 1                Claude 实例 2                Claude 实例 3
├── developer-1              ├── developer-2              ├── developer-3
│   ├── git pull             │   ├── git pull             │   ├── git pull
│   ├── 选任务 #1,#2         │   ├── 选任务 #3,#4         │   ├── 选任务 #5,#6
│   └── PR → main            │   └── PR → main            │   └── PR → main
```

每人各自操作 Claude，说"直接开发"，Claude 展示任务清单，输入编号开始。

---

## 前后端分离项目分工建议

对于前后端分离的项目（如 React + FastAPI），推荐按 **API 接口** 分工：

```
scaffold 阶段先定义 API 契约（OpenAPI/Swagger）:

# API 契约（shared/api.yaml）
POST   /api/products        创建商品
GET    /api/products        商品列表
GET    /api/products/:id    商品详情
POST   /api/cart/add        添加购物车
POST   /api/orders          创建订单
POST   /api/pay             发起支付
```

分工方式：

| 人 | 负责 | 产出 |
|----|------|------|
| **第 1 个人** | 后端 API + 数据库 + 业务逻辑 | FastAPI 路由、模型、服务层 |
| **第 2 个人** | 前端页面 + 组件 + 对接 API | React 页面、组件、API 调用 |
| **第 3 个人** | 后端其他模块 / 前端其他页面 | 按任务分配 |

好处：
- API 契约是 shared 的，前后端可以并行开发
- 前端用 mock 数据先开发，后端 API 完成后切换
- 减少联调冲突，接口定义清晰

scaffold 阶段产出 API 契约后，前后端各自拉取，互不阻塞。

---

## 0. 比赛前（architect 准备）

```bash
# 1. 搭建项目骨架
mkdir <项目名> && cd <项目名>
git init

# 2. 创建基础结构
# 根据 tech-stack.md 搭建目录、配置、基础代码

# 3. 提交骨架
git add -A
git commit -m "chore: init project skeleton"

# 4. 推送到远程（团队共享）
git remote add origin <仓库地址>
git push -u origin main
```

---

## 1. Architect 需求拆解

```bash
# 在 Claude Code 中
> 比赛模式：[描述你的需求]
```

例如：

```bash
> 比赛模式：做一个团队协作工具
```

architect 会先做需求拆解：

```
📋 需求拆解

  维度          结果
  ──────────    ──────────────────────
  核心功能      [从题目提取的主要功能]
  用户角色      [管理员/普通用户/访客]
  技术约束      [Web端/移动端/已有技术栈]
  待确认项      [题目没说清楚但必须决定的点]

请确认以上拆解结果:
  ✅ 正确 / ❌ 需调整 / ➕ 需补充
```

**architect 会先读取 `~/ai/config/project/tech-stack.md`（运行时路径），确保方案基于已有技术栈。**

用户确认后，进入 plan 阶段。

---

## 2. Architect 规划

architect 产出带编号、带优先级的 tasks.md 后，**等用户确认 plan 再进入下一步**：

```bash
# architect 产出 plan 和 tasks 后
⏸️  等待用户确认

  用户需要逐项对照原始需求:
  ✅ 正确 / ❌ 有误 / ➕ 需补充 / ➖ 需删减

  确认通过后 → 交给 scaffold
```

**规则：用户未确认前，scaffold 不得开始搭骨架，developer 不得开始写代码。**

---

## 3. Scaffold 搭建骨架

用户确认 plan 后，scaffold 负责搭建项目骨架：

```bash
# scaffold 在 Claude Code 中
> scaffold：根据 plan 搭建项目骨架
```

scaffold 需要完成：

1. **后端框架初始化** — 根据 tech-stack.md 初始化后端框架（Express/FastAPI/Django 等）
2. **前端框架初始化** — 初始化前端框架（React/Vue/Next.js 等）
3. **共享代码** — 创建 shared 类型定义、工具函数、数据库 schema 等
4. **基础配置** — package.json、tsconfig、lint 配置、环境变量模板等
5. **提交并推送** — push 到 main，确保骨架可运行
6. **任务分配** — 按依赖关系分配任务给 developer-1/2/3

```bash
# scaffold 完成后
git add -A
git commit -m "chore: scaffold project skeleton"
git push origin main
```

scaffold 产出后，将 tasks 分配给具体的人：

```markdown
## Tasks

### developer-1 负责（模块 A）
- [ ] #1 [P0] 用户注册接口
  - 验收标准: POST /api/register 返回 201
- [ ] #2 [P0] 登录鉴权
  - 验收标准: POST /api/login 返回 JWT token

### developer-2 负责（模块 B）
- [ ] #3 [P1] 用户列表页
  - 验收标准: GET /api/users 返回分页列表

### developer-3 负责（模块 C）
- [ ] #4 [P1] 数据导出
  - 验收标准: 导出 CSV 文件
```

**关键：scaffold 的骨架必须能跑起来，developer 拉下来就能启动开发。**

---

## 4. 每个 Developer 拉取并创建分支

```bash
# 每个人都执行
git pull origin main

# 各自创建分支（每个 task 一个分支）
git checkout -b feat/task-1      # developer-1
git checkout -b feat/task-2      # developer-2
git checkout -b feat/task-3      # developer-3
```

---

## 5. 并行开发（各自独立）

每个人在自己的分支上工作，遵循 TDD 流程：

```bash
# developer-1
git checkout feat/task-1
# 实现 Task #1, #4 (TDD)

# developer-2
git checkout feat/task-2
# 实现 Task #2 (TDD)

# developer-3
git checkout feat/task-3
# 实现 Task #3 (TDD, blocked by #2)
```

**关键：每个人只改自己模块的文件，不碰别人的。**

```
developer-1: src/routes/module_a/, src/models/module_a/
developer-2: src/routes/module_b/, src/models/module_b/
developer-3: src/routes/module_c/, src/models/module_c/
```

---

## 6. 定期同步（避免冲突）

每完成一个 task，同步一次：

```bash
# 1. 拉取最新的 main
git fetch origin
git rebase origin/main

# 2. 如果有冲突，解决后继续
git rebase --continue

# 3. 推送自己的分支
git push origin feat/task-1
```

---

## 7. 功能测试 + 提交 PR

每个模块完成后，**先跑功能测试，通过再提 PR**：

```bash
# 1. 运行测试
npm test / pytest / go test ./...

# 2. 启动项目，手动验证核心功能
npm run dev
# 浏览器访问，走一遍核心流程

# 3. 测试通过后，提交 PR
gh pr create --title "feat(task-1): 完成用户注册接口" --body "..."
```

**规则：测试不通过，不得提 PR。**

```
developer 实现完
  ├── 功能测试通过 ✅ → 提 PR
  └── 功能测试失败 ❌ → 修复 → 重测 → 通过后再提 PR
```

**合并顺序：先合依赖少的模块**

```
1. developer-1 的 task-1 先合并（其他模块依赖它）
2. developer-2 的 task-2 合并
3. developer-3 的 task-3 最后合并（依赖 task-2）
```

---

## 8. 共享记忆机制

### 共享文件（所有人读）

| 文件 | 位置 | 用途 |
|------|------|------|
| plan.md | `docs/forge/<项目名>/plan.md` | 架构决策、scope |
| tasks.md | `docs/forge/<项目名>/tasks.md` | 任务清单、分配、进度、优先级 |
| tech-stack.md | `~/ai/config/project/tech-stack.md` | 技术栈约定 |
| CLAUDE.md | `config/claude/CLAUDE.md` | 工作流规则 |

### 进度同步（tasks.md 实时更新）

```markdown
## Tasks

### developer-1 负责
- [x] #1 [P0] 用户注册接口 ✅ [时间]
- [x] #2 [P0] 登录鉴权 ✅ [时间]
- [ ] #3 [P1] 用户列表页 🔄 进行中

### developer-2 负责
- [ ] #4 [P1] 数据导出 ⏳ 待开始
- [ ] #5 [P1] 通知模块 ⏳ 待开始

### developer-3 负责
- [ ] #6 [P2] 高级搜索 ⏳ 待开始
```

**规则：每完成一个 task，立即更新 tasks.md 并 push。**

---

## 9. 避免冲突的规则

### 文件隔离

```
每个人只改自己模块的文件：
├── src/routes/
│   ├── module_a.ts    ← 只有 developer-1 改
│   ├── module_b.ts    ← 只有 developer-2 改
│   └── module_c.ts    ← 只有 developer-3 改
├── src/models/
│   ├── module_a.ts    ← 只有 developer-1 改
│   ├── module_b.ts    ← 只有 developer-2 改
│   └── module_c.ts    ← 只有 developer-3 改
└── src/shared/        ← 共享代码，需要协调
    └── utils.ts       ← 谁改谁负责，改完通知其他人
```

### 共享代码规则

- `src/shared/` 下的代码改动，必须在 PR 中说明
- 如果需要改别人模块的文件，先沟通
- 新增共享函数/类型，放到 `src/shared/`

### Git 规则

- 每个人只推自己的分支
- 不直接推 main
- PR review 后再合并
- 合并后通知其他人 pull

---

## 10. 冲突解决流程

```bash
# 1. 发现冲突
git rebase origin/main
# CONFLICT (content): Merge conflict in src/shared/utils.ts

# 2. 解决冲突
$EDITOR src/shared/utils.ts
# 保留双方需要的代码

# 3. 继续 rebase
git add src/shared/utils.ts
git rebase --continue

# 4. 推送
git push origin feat/task-1
```

**如果冲突复杂，找 architect 协调。**

---

## 11. 完整流程

### 模式一：完整流程（architect → scaffold → developer）

```
第 1 个人（主控 Claude）
  ├── architect: 需求拆解 → 读 tech-stack.md → speckit plan → tasks
  ├── 🔵 用户确认 plan
  ├── scaffold: 后端 + 前端骨架 → push main → 分配任务
  ├── 退出 Claude
  └── 也参与开发（选剩余任务，如 #5,#6）

第 2 个人（Claude 实例 2）      第 3 个人（Claude 实例 3）
  ├── git pull                   ├── git pull
  ├── checkout feat/task-1       ├── checkout feat/task-2
  ├── 选任务 #1,#2               ├── 选任务 #3,#4
  ├── 实现（TDD）                ├── 实现（TDD）
  ├── 功能测试 ✅ → 提 PR        ├── 功能测试 ✅ → 提 PR
  └── 等待 review                └── 等待 review

第 1 个人（也参与开发，同时 review PR → 合并 → 通知 pull）
```

### 模式二：直接开发（跳过 architect + scaffold）

```
触发: 用户说"直接开发"或"继续开发"

前提: 项目骨架已存在，tasks.md 已有带编号的任务清单
```

**Step 1: 展示任务清单**

Claude 读取 `docs/forge/<项目名>/tasks.md`，输出所有任务：

```
📋 当前任务清单:

  ✅ #1 [P0] 用户注册模块
  ✅ #2 [P0] 用户登录模块
  🔄 #3 [P1] 商品管理 CRUD
  ⏳ #4 [P1] 购物车模块
  ⏳ #5 [P2] 订单处理模块
  ⏳ #6 [P2] 支付集成

请选择任务编号（多个用逗号分隔，如 4,5,6）:
```

**Step 2: 用户输入编号**

```bash
> 4,5,6
```

**Step 3: 详细设计（默认）或跳过**

选完任务后，Claude 输出详细设计：

```
📝 #4 [P1] 购物车模块 — 详细设计

  技术方案:
  ├── 数据模型: Cart { id, user_id, items: CartItem[], created_at }
  ├── API 接口: POST /cart/add, DELETE /cart/remove, GET /cart
  ├── 依赖: #1 用户注册模块（已有 User 模型）
  └── 关键逻辑: 数量校验、库存检查、价格计算

  实现计划:
  ├── 1. 创建 src/models/cart.ts（数据模型）
  ├── 2. 创建 src/routes/cart.ts（API 路由）
  ├── 3. 创建 src/services/cart.ts（业务逻辑）
  └── 4. 编写测试 test/cart.test.ts

  预估改动文件: 4 个
  风险点: 库存并发扣减

请确认:
  ✅ 方案正确，开始实现
  ❌ 需要调整（说明原因）
  ⏭️ 跳过校验，直接实现
```

用户回复：
- `✅` 或直接回车 → 确认方案，开始实现
- `❌ + 说明` → Claude 调整方案后重新输出
- `跳过` / `skip` → 跳过设计校验，直接实现

**Step 4: 实现**

```
第 1 个人                    第 2 个人                    第 3 个人
  ├── 选 #4 购物车模块        ├── 选 #5 订单处理模块       ├── 选 #6 支付集成
  ├── git pull                ├── git pull                 ├── git pull
  ├── checkout feat/task-4    ├── checkout feat/task-5     ├── checkout feat/task-6
  ├── 详细设计 → 确认         ├── 详细设计 → 确认          ├── 跳过校验
  ├── 实现 → PR               ├── 实现 → PR                ├── 实现 → PR
  └── 等待 review             └── 等待 review              └── 等待 review
```

---

## 12. 常见问题

### Q: 两个人改了同一个文件怎么办？

```bash
# 1. 先沟通，确定谁改
# 2. 另一个人等对方改完再改
# 3. 或者拆分文件，各管各的
```

### Q: 需要改别人模块的代码怎么办？

```bash
# 1. 先在 tasks.md 中说明
# 2. 在自己的分支上改
# 3. PR 中标注"修改了 src/shared/utils.ts"
# 4. architect review 后合并
```

### Q: 怎么知道别人的进度？

```bash
# 查看 tasks.md
cat docs/forge/<项目名>/tasks.md

# 或者在 Claude Code 中
> 查看当前任务进度
```

### Q: 合并后代码跑不起来怎么办？

```bash
# 1. 先 pull 最新 main
git pull origin main

# 2. 安装依赖
[包管理器] install

# 3. 运行测试
[包管理器] test

# 4. 如果失败，找相关 developer 协调
```

### Q: 时间不够了怎么办？

```bash
# 砍需求优先级
# 1. P2 全部砍掉
# 2. 剩余不到 30% 时间，P1 也砍
# 3. 全力保 P0
# 4. 所有 developer 集中做 P0
```
