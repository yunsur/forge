# 比赛工作流实操指南

---

## 0. 比赛前准备（一次性）

```bash
# 1. 安装 forge
cd /path/to/forge
./forge install
./forge init

# 2. 加载环境
source ~/ai/env.sh

# 3. 检查环境
./forge doctor
```

比赛开始后填写两个文件：

```bash
# 填写技术栈
$EDITOR ~/ai/config/project/tech-stack.md

# 填写部署逻辑
$EDITOR shell/deploy.sh

# 重新部署配置
forge init config
```

---

## 1. 启动比赛

```bash
# 启动 Claude Code
claude

# 说"比赛模式"激活工作流
> 比赛模式：[描述你的需求]
```

例如：

```bash
> 比赛模式：实现一个用户管理系统，支持注册、登录、个人信息编辑
```

Claude 会自动切换到比赛工作流。

---

## 2. Architect 需求拆解（粗需求 → 细化需求）

当输入是粗需求时，architect 先做需求拆解：

```
architect 会输出:

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

用户确认后，进入 plan 阶段。

---

## 3. Architect 规划（speckit plan → tasks）

Claude 会自动执行：

```bash
# 产出 plan 文件
speckit plan
# → docs/forge/<项目名>/plan.md

# 产出 tasks 清单（每项带 task-id + 优先级）
speckit tasks
# → docs/forge/<项目名>/tasks.md
```

你会看到类似输出：

```
## Tasks

- [ ] #1 [P0] 用户注册接口
  - 验收标准: POST /api/register 返回 201，数据库写入用户记录
- [ ] #2 [P0] 登录鉴权
  - 验收标准: POST /api/login 返回 JWT token
- [ ] #3 [P1] 用户列表页
  - 验收标准: GET /api/users 返回分页列表
- [ ] #4 [P2] 数据导出
  - 验收标准: 导出 CSV 文件
```

**优先级含义：**
- **P0** — Must-have，MVP 核心，必须完成
- **P1** — Should-have，重要，P0 完成后视时间做
- **P2** — Nice-to-have，锦上添花，P0+P1 都完成后才做

**确认 plan 后，进入 scaffold 阶段。**

---

## 3.5 Plan 人工对照验收（关键环节）

architect 产出 plan 和 tasks 后，**暂停，等用户确认**。

Claude 会输出：

```
⏸️  等待用户确认 plan

  原始需求: [用户输入的原始需求]

  Plan 概要:
  ├── Scope: [要做什么]
  ├── Anti-scope: [明确不做什么]
  ├── 技术选型: [关键技术决策]
  └── 风险: [已识别风险及应对]

  Tasks:
  1. #1 [P0] 用户注册接口 → 验收标准
  2. #2 [P0] 登录鉴权 → 验收标准
  3. #3 [P1] 用户列表页 → 验收标准

  请逐项确认:
  ✅ 正确 / ❌ 有误 / ➕ 需补充 / ➖ 需删减
```

用户需要逐项确认：

```bash
# 逐项对照原始需求和 plan
✅ Scope 正确
❌ 选型不对，应该用 [替代方案]
➕ 加一个 [功能] 的 task
➖ [某功能] 不需要，比赛只要求 [核心功能]
```

Claude 修正后重新输出，用户再次确认。

**规则：用户未确认前，scaffold 不得开始搭骨架，developer 不得开始写代码。**

---

## 4. Scaffold 搭建骨架

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

```
🏗️ Scaffold: 搭建项目骨架
  ├── 后端: Express + TypeScript ✅
  ├── 前端: React + Vite ✅
  ├── shared: 类型定义 + 工具函数 ✅
  ├── 配置: tsconfig, eslint, env ✅
  ├── 测试: 项目可启动 ✅
  ├── git push origin main ✅
  └── 任务分配:
      ├── developer-1: #1, #4 (independent, parallel)
      ├── developer-2: #2 (independent, parallel)
      └── developer-3: #3 (blocked by #2, starts after merge)
```

scaffold 完成后，developer 才能开始开发。

---

## 5. Developer 并行开发（TDD + 独立分支）

每个 developer 在自己的分支上开发，遵循 TDD 流程：

```
分支策略:
main
 ├── feat/task-1   (developer-1)
 ├── feat/task-2   (developer-2)
 └── feat/task-3   (developer-3)
```

每个 task 的 TDD 流程：

```
Task #1: [P0] 用户注册接口
├── 1. 读 task + 验收标准
├── 2. 🔴 写失败测试（TDD red）
├── 3. 🟢 写最小实现（TDD green）
├── 4. ♻️ 重构（如需要）
├── 5. ✅ 标记完成
└── 6. 等待 tester 验证
```

你会看到：

```
📝 Task #1: [P0] 用户注册接口
  🔴 写测试: test_register_works
  🟢 实现: POST /api/register 路由
  ✅ 测试通过
  📋 标记完成
```

**并行调度规则：**
- 无依赖任务 → 并行分配给不同 developer
- 有依赖任务 → 等前置 task merge 后再启动
- developer 提前完成 → architect 从 P1 队列重分配

---

## 6. Tester 验证（逐 task 验证）

每个 task 完成后，tester 立即验证：

```
🔍 验证 Task #1: [P0] 用户注册接口
  ├── Scope Check: ✅ 只改了 [相关文件]
  ├── Functional: ✅ 测试通过
  ├── Plan Alignment: ✅ 符合 plan 意图
  └── Verdict: PASS → 继续下一个
```

如果失败：

```
🔍 验证 Task #2: [P0] 登录鉴权
  ├── Scope Check: ⚠️ 改了 [无关文件]（不在 task 范围内）
  ├── Functional: ❌ [具体问题]
  ├── Verdict: FAIL
  └── → developer 修复
```

---

## 7. MVP Checkpoint

所有 P0 任务完成时，触发 MVP checkpoint：

```
🎯 MVP Checkpoint

  P0 任务状态:
  ├── #1 [P0] 用户注册接口 ✅
  ├── #2 [P0] 登录鉴权 ✅
  └── #3 [P0] 核心链路测试 ✅

  核心链路可演示: ✅

  决策:
  ├── ✅ 核心流程可用 → 冻结范围，准备 demo
  └── ❌ 核心流程有问题 → 全力修复 P0 bug
```

**MVP 后规则：**
- 冻结范围 — 不再加新功能，只修 P0 代码的 bug
- P1/P2 视剩余时间决定
- 目标是能演示核心流程

---

## 8. 异常回退

| 场景 | 处理 |
|------|------|
| 任务超时 (2x 预估) | 标记 blocked，跳过，做下一个 P0 |
| 分支冲突无法解决 | 换人 + 新分支重新做 |
| 所有 P0 被阻塞 | 用户决定：简化范围 or 延长时间 |
| merge 后测试失败 | revert merge，developer 修复后重新提交 |
| 50% 时间无 P0 完成 | 紧急砍范围：只保 1 个核心功能 |

核心原则：**不停流水线**。一个任务阻塞就绕过去，目标是 MVP，不是完美。

---

## 9. 循环直到完成

```
Plan Review: ✅ 用户确认 plan → 开发

Task #1: ✅ developer → tester → PASS
Task #2: ✅ developer → tester → PASS
Task #3: ❌ developer → tester → FAIL → 修复 → PASS
Task #4: ✅ developer → tester → PASS
Task #5: ✅ developer → tester → PASS

MVP Checkpoint: 所有 P0 完成 ✅
```

---

## 10. 提交代码

```bash
# 在 Claude Code 中
> /commit "feat(scope): [提交信息]"
```

Claude 自动执行：
1. `git add -A`
2. 运行测试
3. `git commit -m "feat(scope): [提交信息]"`

---

## 11. 赛后验证

比赛结束后，进入验证阶段：

```bash
# 说"赛后验证"
> 赛后验证：对当前代码进行全面检查
```

### 安全扫描

```bash
> /security-scan
```

输出：

```
🔒 安全扫描
  ✅ 敏感信息: 未发现
  ✅ 依赖安全: 审计通过
  ⚠️  [安全问题]: 发现 1 处（[文件:行号]）
  → 修复后重扫
```

### 交叉测试

Claude 会作为 cross-tester 黑盒测试：

```
🔍 交叉测试
  ├── 用户流程: ✅ [核心流程验证]
  ├── 边界测试: ✅ [边界条件验证]
  ├── 集成测试: ✅ [模块间联调验证]
  └── Verdict: PASS
```

### 修复问题

```
发现问题 → developer 修复 → 重新验证 → 通过
```

---

## 12. 部署

```bash
# 在 Claude Code 中
> /deploy prod user@server:/app
```

Claude 自动执行：
1. 检查是否有未提交的变更
2. 运行测试
3. 构建项目
4. 执行 `deploy.sh` 中的部署逻辑

---

## 13. 完整流程总结

```
比赛前
  └── 填写 tech-stack.md + deploy.sh

比赛开始
  ├── 1. architect: 需求拆解 → 细化需求文档
  ├── 2. architect: speckit plan → tasks（带 #id + P0/P1/P2）
  ├── 3. 🔵 用户对照 plan 逐项确认 ← 人机交互验收
  ├── 4. scaffold: 搭建前后端骨架 + shared 代码 → push main
  ├── 5. scaffold: 按依赖关系分配任务
  ├── 6. developer: 并行 TDD 开发（独立分支 feat/task-{id}）
  ├── 7. tester: 逐 task 即时验证
  ├── 8. 循环 6-7 直到所有 task 完成
  ├── 9. MVP Checkpoint: P0 完成 → 冻结范围
  └── 10. /commit 提交

赛后
  ├── 11. /security-scan 安全扫描
  ├── 12. 交叉测试
  ├── 13. 修复问题
  └── 14. /deploy 部署
```

### 直接开发（跳过 architect + scaffold）

```
触发: 用户说"直接开发"或"继续开发"
前提: 项目骨架已存在，tasks.md 已有带编号的任务清单

  ├── 1. Claude 读取 tasks.md，展示任务清单（带 #编号）
  ├── 2. 用户输入要开发的任务编号（如 4,5,6）
  ├── 3. Claude 输出详细设计 → 用户确认 / 调整 / 跳过
  ├── 4. developer 逐 task 实现
  ├── 5. 功能测试通过 → 提 PR
  ├── 6. 循环 4-5 直到所选 task 完成
  └── 7. /commit 提交
```

---

## 常见问题

### Q: 中途发现需要新功能怎么办？

```bash
# 告诉 architect 更新 plan
> architect: 需要加一个 [新功能]，请更新 plan

# 不要自己加（会 drift）
```

### Q: tester 说 scope drift 怎么办？

```bash
# 回退无关改动
git checkout -- [误改的文件]

# 只保留 task 范围内的改动
```

### Q: 测试一直失败怎么办？

```bash
# 让 Claude 调试
> developer: task [N] 的测试失败了，请调试

# 使用 systematic-debugging skill
```

### Q: 如何跳过某个 task？

```bash
# 告诉 architect 更新 plan
> architect: task [N] 不做了，请从 tasks 中移除
```

### Q: 时间不够了怎么办？

```bash
# 砍需求优先级
# 1. P2 全部砍掉
# 2. 剩余不到 30% 时间，P1 也砍
# 3. 全力保 P0
# 4. 所有 developer 集中做 P0
```
