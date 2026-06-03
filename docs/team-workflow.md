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

## 1. Architect 规划并分配任务

```bash
# 在 Claude Code 中
> 比赛模式：[描述你的需求]
```

例如：

```bash
> 比赛模式：实现一个订单处理系统，包含商品管理、购物车、支付模块
```

architect 产出 tasks.md 后，**等用户确认 plan 再分配给具体的人**：

```bash
# architect 产出 plan 和 tasks 后
⏸️  等待用户确认

  用户需要逐项对照原始需求:
  ✅ 正确 / ❌ 有误 / ➕ 需补充 / ➖ 需删减

  确认通过后 → 分配任务
```

**规则：用户未确认前，不得开始开发。**

确认后，分配给具体的人：

```markdown
## Tasks

### developer-1 负责（模块 A）
- [ ] Task 1: [任务名称]
- [ ] Task 2: [任务名称]
- [ ] Task 3: [任务名称]

### developer-2 负责（模块 B）
- [ ] Task 4: [任务名称]
- [ ] Task 5: [任务名称]
- [ ] Task 6: [任务名称]

### developer-3 负责（模块 C）
- [ ] Task 7: [任务名称]
- [ ] Task 8: [任务名称]
- [ ] Task 9: [任务名称]
```

---

## 2. 每个 Developer 拉取并创建分支

```bash
# 每个人都执行
git pull origin main

# 各自创建分支
git checkout -b feat/module-a      # developer-1
git checkout -b feat/module-b      # developer-2
git checkout -b feat/module-c      # developer-3
```

---

## 3. 并行开发（各自独立）

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

## 4. 定期同步（避免冲突）

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

## 5. 提交 PR 并合并

每个模块完成后，提交 PR：

```bash
# 在 GitHub 上创建 PR
feat/module-a → main

# 或者用 gh CLI
gh pr create --title "feat: module A" --body "完成模块 A 的核心功能"
```

**合并顺序：先合依赖少的模块**

```
1. developer-1 的 module-a 先合并（其他模块依赖它）
2. developer-2 的 module-b 合并
3. developer-3 的 module-c 最后合并（依赖模块 A 和 B）
```

---

## 6. 共享记忆机制

### 共享文件（所有人读）

| 文件 | 位置 | 用途 |
|------|------|------|
| plan.md | `docs/forge/<项目名>/plan.md` | 架构决策、scope |
| tasks.md | `docs/forge/<项目名>/tasks.md` | 任务清单、分配、进度 |
| tech-stack.md | `config/project/tech-stack.md` | 技术栈约定 |
| CLAUDE.md | `config/claude/CLAUDE.md` | 工作流规则 |

### 进度同步（tasks.md 实时更新）

```markdown
## Tasks

### developer-1 负责
- [x] Task 1: [任务名称] ✅ [时间]
- [x] Task 2: [任务名称] ✅ [时间]
- [ ] Task 3: [任务名称] 🔄 进行中

### developer-2 负责
- [ ] Task 4: [任务名称] ⏳ 待开始
- [ ] Task 5: [任务名称] ⏳ 待开始
- [ ] Task 6: [任务名称] ⏳ 待开始

### developer-3 负责
- [ ] Task 7: [任务名称] ⏳ 待开始
- [ ] Task 8: [任务名称] ⏳ 待开始
- [ ] Task 9: [任务名称] ⏳ 待开始
```

**规则：每完成一个 task，立即更新 tasks.md 并 push。**

---

## 7. 避免冲突的规则

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
git push origin feat/module-a
```

**如果冲突复杂，找 architect 协调。**

---

## 9. 完整流程

```
architect
  ├── 1. 搭建骨架 → push main
  ├── 2. speckit plan → tasks
  ├── 3. 🔵 用户确认 plan（人机对照验收）
  ├── 4. 分配任务给 developer-1/2/3
  └── 5. 协调冲突、review PR

developer-1                  developer-2                  developer-3
  ├── git pull               ├── git pull                 ├── git pull
  ├── checkout feat/module-a ├── checkout feat/module-b   ├── checkout feat/module-c
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
