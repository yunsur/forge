# 3 人团队协作指南

---

## 角色分工

```
architect (规划)     developer-1 (实现)    developer-2 (实现)    developer-3 (实现)
     │                    │                    │                    │
     ├─ plan.md ──────────┤────────────────────┤────────────────────┤
     ├─ tasks.md ─────────┤────────────────────┤────────────────────┤
     │                    │                    │                    │
     │                    ├─ Task 1,2 ─────────┤                    │
     │                    │                    ├─ Task 3,4 ─────────┤
     │                    │                    │                    ├─ Task 5,6 ─────
     │                    │                    │                    │
     └────────────────────┴──── 合并到 main ───┴────────────────────┘
```

| 角色 | 职责 | 人数 |
|------|------|------|
| architect | 规划、拆任务、分配、协调 | 1 |
| developer | 按分配的 task 实现 | 2-3 |

---

## 0. 比赛前（architect 准备）

```bash
# 1. 搭建项目骨架
mkdir my-project && cd my-project
git init

# 2. 创建基础结构
# 根据 tech-stack.md 搭建目录、配置、基础代码

# 3. 提交骨架
git add -A
git commit -m "chore: init project skeleton"

# 4. 推送到远程（团队共享）
git remote add origin git@github.com:team/project.git
git push -u origin main
```

---

## 1. Architect 规划并分配任务

```bash
# 在 Claude Code 中
> 比赛模式：实现一个电商系统，包含用户、商品、订单模块
```

architect 产出 tasks.md 后，**分配给具体的人**：

```markdown
## Tasks

### developer-1 负责（用户模块）
- [ ] Task 1: 用户注册 API
- [ ] Task 2: 用户登录 API
- [ ] Task 3: 用户信息 CRUD

### developer-2 负责（商品模块）
- [ ] Task 4: 商品列表 API
- [ ] Task 5: 商品详情 API
- [ ] Task 6: 商品搜索

### developer-3 负责（订单模块）
- [ ] Task 7: 创建订单 API
- [ ] Task 8: 订单支付
- [ ] Task 9: 订单状态管理
```

---

## 2. 每个 Developer 拉取并创建分支

```bash
# 每个人都执行
git pull origin main

# 各自创建分支
git checkout -b feat/user-module      # developer-1
git checkout -b feat/product-module   # developer-2
git checkout -b feat/order-module     # developer-3
```

---

## 3. 并行开发（各自独立）

每个人在自己的分支上工作：

```bash
# developer-1
git checkout feat/user-module
# 实现 Task 1, 2, 3

# developer-2
git checkout feat/product-module
# 实现 Task 4, 5, 6

# developer-3
git checkout feat/order-module
# 实现 Task 7, 8, 9
```

**关键：每个人只改自己模块的文件，不碰别人的。**

```
developer-1: src/routes/user.ts, src/models/user.ts
developer-2: src/routes/product.ts, src/models/product.ts
developer-3: src/routes/order.ts, src/models/order.ts
```

---

## 4. 定期同步（避免冲突）

每完成一个 task，同步一次：

```bash
# 1. 拉取最新的 main
git fetch origin
git rebase origin/main

# 2. 如果有冲突，解决后继续
git rebase --continue

# 3. 推送自己的分支
git push origin feat/user-module
```

---

## 5. 提交 PR 并合并

每个模块完成后，提交 PR：

```bash
# 在 GitHub 上创建 PR
feat/user-module → main

# 或者用 gh CLI
gh pr create --title "feat: user module" --body "完成用户注册、登录、CRUD"
```

**合并顺序：先合骨架依赖少的模块**

```
1. developer-1 的 user-module 先合并（其他模块依赖用户）
2. developer-2 的 product-module 合并
3. developer-3 的 order-module 最后合并（依赖用户和商品）
```

---

## 6. 共享记忆机制

### 共享文件（所有人读）

| 文件 | 位置 | 用途 |
|------|------|------|
| plan.md | `docs/forge/project/plan.md` | 架构决策、scope |
| tasks.md | `docs/forge/project/tasks.md` | 任务清单、分配、进度 |
| tech-stack.md | `config/project/tech-stack.md` | 技术栈约定 |
| CLAUDE.md | `config/claude/CLAUDE.md` | 工作流规则 |

### 进度同步（tasks.md 实时更新）

```markdown
## Tasks

### developer-1 负责
- [x] Task 1: 用户注册 API ✅ 2024-01-15 10:30
- [x] Task 2: 用户登录 API ✅ 2024-01-15 11:00
- [ ] Task 3: 用户信息 CRUD 🔄 进行中

### developer-2 负责
- [ ] Task 4: 商品列表 API ⏳ 待开始
- [ ] Task 5: 商品详情 API ⏳ 待开始
- [ ] Task 6: 商品搜索 ⏳ 待开始

### developer-3 负责
- [ ] Task 7: 创建订单 API ⏳ 待开始
- [ ] Task 8: 订单支付 ⏳ 待开始
- [ ] Task 9: 订单状态管理 ⏳ 待开始
```

**规则：每完成一个 task，立即更新 tasks.md 并 push。**

---

## 7. 避免冲突的规则

### 文件隔离

```
每个人只改自己模块的文件：
├── src/routes/
│   ├── user.ts       ← 只有 developer-1 改
│   ├── product.ts    ← 只有 developer-2 改
│   └── order.ts      ← 只有 developer-3 改
├── src/models/
│   ├── user.ts       ← 只有 developer-1 改
│   ├── product.ts    ← 只有 developer-2 改
│   └── order.ts      ← 只有 developer-3 改
└── src/shared/       ← 共享代码，需要协调
    └── utils.ts      ← 谁改谁负责，改完通知其他人
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

## 8. 冲突解决流程

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
git push origin feat/user-module
```

**如果冲突复杂，找 architect 协调。**

---

## 9. 完整流程

```
architect
  ├── 1. 搭建骨架 → push main
  ├── 2. speckit plan → tasks
  ├── 3. 分配任务给 developer-1/2/3
  └── 4. 协调冲突、review PR

developer-1                  developer-2                  developer-3
  ├── git pull               ├── git pull                 ├── git pull
  ├── checkout feat/user     ├── checkout feat/product    ├── checkout feat/order
  ├── 实现 Task 1,2,3        ├── 实现 Task 4,5,6          ├── 实现 Task 7,8,9
  ├── 每完成一个 task:        ├── 每完成一个 task:          ├── 每完成一个 task:
  │   git push               │   git push                 │   git push
  │   更新 tasks.md          │   更新 tasks.md            │   更新 tasks.md
  ├── 完成后 PR → main       ├── 完成后 PR → main         ├── 完成后 PR → main
  └── 等待 review            └── 等待 review              └── 等待 review

architect review PR → 合并 → 通知其他人 pull
```

---

## 10. 常见问题

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
# 3. PR 中标注"修改了 shared/utils.ts"
# 4. architect review 后合并
```

### Q: 怎么知道别人的进度？

```bash
# 查看 tasks.md
cat docs/forge/project/tasks.md

# 或者在 Claude Code 中
> 查看当前任务进度
```

### Q: 合并后代码跑不起来怎么办？

```bash
# 1. 先 pull 最新 main
git pull origin main

# 2. 安装依赖
npm install

# 3. 运行测试
npm test

# 4. 如果失败，找相关 developer 协调
```
