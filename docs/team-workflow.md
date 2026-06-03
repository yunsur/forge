# 3 人团队协作指南

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
├── architect: plan → tasks
├── scaffold: 搭骨架 → push main
└── 也参与开发（选剩余任务）

第 2 个人                          第 3 个人
├── developer                      ├── developer
│   ├── git pull                   │   ├── git pull
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

## 1. Architect 规划

```bash
# 在 Claude Code 中
> 比赛模式：[描述你的需求]
```

例如：

```bash
> 比赛模式：实现一个订单处理系统，包含商品管理、购物车、支付模块
```

**architect 会先读取 `~/ai/config/project/tech-stack.md`（运行时路径），确保方案基于已有技术栈。**

architect 产出带编号的 tasks.md 后，**等用户确认 plan 再进入下一步**：

```bash
# architect 产出 plan 和 tasks 后
⏸️  等待用户确认

  用户需要逐项对照原始需求:
  ✅ 正确 / ❌ 有误 / ➕ 需补充 / ➖ 需删减

  确认通过后 → 交给 scaffold
```

**规则：用户未确认前，scaffold 不得开始搭骨架，developer 不得开始写代码。**

---

## 2. Scaffold 搭建骨架

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
- [ ] #1 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #2 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #3 [任务名称]
  - 验收标准: [具体可验证的条件]

### developer-2 负责（模块 B）
- [ ] #4 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #5 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #6 [任务名称]
  - 验收标准: [具体可验证的条件]

### developer-3 负责（模块 C）
- [ ] #7 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #8 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #9 [任务名称]
  - 验收标准: [具体可验证的条件]
```

**关键：scaffold 的骨架必须能跑起来，developer 拉下来就能启动开发。**

---

## 3. 每个 Developer 拉取并创建分支

```bash
# 每个人都执行
git pull origin main

# 各自创建分支
git checkout -b feat/module-a      # developer-1
git checkout -b feat/module-b      # developer-2
git checkout -b feat/module-c      # developer-3
```

---

## 4. 并行开发（各自独立）

每个人在自己的分支上工作：

```bash
# developer-1
git checkout feat/module-a
# 实现 Task 1, 2, 3

# developer-2
git checkout feat/module-b
# 实现 Task 4, 5, 6

# developer-3
git checkout feat/module-c
# 实现 Task 7, 8, 9
```

**关键：每个人只改自己模块的文件，不碰别人的。**

```
developer-1: src/routes/module_a/, src/models/module_a/
developer-2: src/routes/module_b/, src/models/module_b/
developer-3: src/routes/module_c/, src/models/module_c/
```

---

## 5. 定期同步（避免冲突）

每完成一个 task，同步一次：

```bash
# 1. 拉取最新的 main
git fetch origin
git rebase origin/main

# 2. 如果有冲突，解决后继续
git rebase --continue

# 3. 推送自己的分支
git push origin feat/module-a
```

---

## 6. 功能测试 + 提交 PR

每个模块完成后，**先跑功能测试，通过再提 PR**：

```bash
# 1. 运行测试
npm test / pytest / go test ./...

# 2. 启动项目，手动验证核心功能
npm run dev
# 浏览器访问，走一遍核心流程

# 3. 测试通过后，提交 PR
gh pr create --title "feat(module-a): 完成模块 A" --body "..."
# 或 GitLab: feat/module-a → main
```

**规则：测试不通过，不得提 PR。**

```
developer 实现完
  ├── 功能测试通过 ✅ → 提 PR
  └── 功能测试失败 ❌ → 修复 → 重测 → 通过后再提 PR
```

**合并顺序：先合依赖少的模块**

```
1. developer-1 的 module-a 先合并（其他模块依赖它）
2. developer-2 的 module-b 合并
3. developer-3 的 module-c 最后合并（依赖模块 A 和 B）
```

---

## 7. 共享记忆机制

### 共享文件（所有人读）

| 文件 | 位置 | 用途 |
|------|------|------|
| plan.md | `docs/forge/<项目名>/plan.md` | 架构决策、scope |
| tasks.md | `docs/forge/<项目名>/tasks.md` | 任务清单、分配、进度 |
| tech-stack.md | `~/ai/config/project/tech-stack.md` | 技术栈约定 |
| CLAUDE.md | `config/claude/CLAUDE.md` | 工作流规则 |

### 进度同步（tasks.md 实时更新）

```markdown
## Tasks

### developer-1 负责
- [x] #1 [任务名称] ✅ [时间]
- [x] #2 [任务名称] ✅ [时间]
- [ ] #3 [任务名称] 🔄 进行中

### developer-2 负责
- [ ] #4 [任务名称] ⏳ 待开始
- [ ] #5 [任务名称] ⏳ 待开始
- [ ] #6 [任务名称] ⏳ 待开始

### developer-3 负责
- [ ] #7 [任务名称] ⏳ 待开始
- [ ] #8 [任务名称] ⏳ 待开始
- [ ] #9 [任务名称] ⏳ 待开始
```

**规则：每完成一个 task，立即更新 tasks.md 并 push。**

---

## 8. 避免冲突的规则

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

## 9. 冲突解决流程

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
git push origin feat/module-a
```

**如果冲突复杂，找 architect 协调。**

---

## 10. 完整流程

### 模式一：完整流程（architect → scaffold → developer）

```
第 1 个人（主控 Claude）
  ├── architect: 读 tech-stack.md → speckit plan → tasks
  ├── 🔵 用户确认 plan
  ├── scaffold: 后端 + 前端骨架 → push main
  ├── 退出 Claude
  └── 也参与开发（选剩余任务，如 #5,#6）

第 2 个人（Claude 实例 2）      第 3 个人（Claude 实例 3）
  ├── git pull                   ├── git pull
  ├── checkout feat/module-a     ├── checkout feat/module-b
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

  ✅ #1 用户注册模块
  ✅ #2 用户登录模块
  🔄 #3 商品管理 CRUD
  ⏳ #4 购物车模块
  ⏳ #5 订单处理模块
  ⏳ #6 支付集成

请选择任务编号（多个用逗号分隔，如 4,5,6）:
```

**Step 2: 用户输入编号**

```bash
> 4,5,6
```

**Step 3: 详细设计（默认）或跳过**

选完任务后，Claude 输出详细设计：

```
📝 #4 购物车模块 — 详细设计

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
  ├── checkout feat/cart      ├── checkout feat/order      ├── checkout feat/payment
  ├── 详细设计 → 确认         ├── 详细设计 → 确认          ├── 跳过校验
  ├── 实现 → PR               ├── 实现 → PR                ├── 实现 → PR
  └── 等待 review             └── 等待 review              └── 等待 review
```

---

## 11. 常见问题

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
