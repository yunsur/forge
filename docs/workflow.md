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

## 2. Architect 规划（speckit plan → tasks）

Claude 会自动执行：

```bash
# 产出 plan 文件
speckit plan
# → docs/forge/<项目名>/plan.md

# 产出 tasks 清单
speckit tasks
# → docs/forge/<项目名>/tasks.md
```

你会看到类似输出：

```
## Tasks

- [ ] #1 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #2 [任务名称]
  - 验收标准: [具体可验证的条件]
- [ ] #3 [任务名称]
  - 验收标准: [具体可验证的条件]
```

**确认 plan 后，进入 scaffold 阶段。**

---

## 2.5 Plan 人工对照验收（关键环节）

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
  1. [任务1] → [验收标准]
  2. [任务2] → [验收标准]
  3. [任务3] → [验收标准]

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

## 2.6 Scaffold 搭建骨架

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

```
🏗️ Scaffold: 搭建项目骨架
  ├── 后端: Express + TypeScript ✅
  ├── 前端: React + Vite ✅
  ├── shared: 类型定义 + 工具函数 ✅
  ├── 配置: tsconfig, eslint, env ✅
  ├── 测试: 项目可启动 ✅
  └── git push origin main ✅
```

scaffold 完成后，developer 才能开始开发。

---

## 3. Developer 实现（逐 task TDD）

Claude 会按 tasks 清单逐个实现。每个 task 的流程：

```
Task 1: [任务名称]
├── 1. 读 task + 验收标准
├── 2. 写失败测试（TDD red）
├── 3. 写最小实现（TDD green）
├── 4. 标记完成
└── 5. 等待 tester 验证
```

你会看到：

```
📝 Task 1: [任务名称]
  🔴 写测试: test_[功能]_works
  🟢 实现: [代码逻辑]
  ✅ 测试通过
  📋 标记完成
```

---

## 4. Tester 验证（逐 task 验证）

每个 task 完成后，tester 立即验证：

```
🔍 验证 Task 1: [任务名称]
  ├── Scope Check: ✅ 只改了 [相关文件]
  ├── Functional: ✅ 测试通过
  ├── Plan Alignment: ✅ 符合 plan 意图
  └── Verdict: PASS → 继续下一个
```

如果失败：

```
🔍 验证 Task 2: [任务名称]
  ├── Scope Check: ⚠️ 改了 [无关文件]（不在 task 范围内）
  ├── Functional: ❌ [具体问题]
  ├── Verdict: FAIL
  └── → developer 修复
```

---

## 5. 循环直到完成

```
Plan Review: ✅ 用户确认 plan → 开发

Task 1: ✅ developer → tester → PASS
Task 2: ✅ developer → tester → PASS
Task 3: ❌ developer → tester → FAIL → 修复 → PASS
Task 4: ✅ developer → tester → PASS
Task 5: ✅ developer → tester → PASS
```

---

## 6. 提交代码

```bash
# 在 Claude Code 中
> /commit "feat(scope): [提交信息]"
```

Claude 自动执行：
1. `git add -A`
2. 运行测试
3. `git commit -m "feat(scope): [提交信息]"`

---

## 7. 赛后验证

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

## 8. 部署

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

## 9. 完整流程总结

```
比赛前
  └── 填写 tech-stack.md + deploy.sh

比赛开始
  ├── 1. architect: speckit plan → tasks
  ├── 2. 🔵 用户对照 plan 逐项确认 ← 人机交互验收
  ├── 3. scaffold: 搭建前后端骨架 + shared 代码 → push main
  ├── 4. developer: 逐 task TDD 实现
  ├── 5. tester: 逐 task 即时验证
  ├── 6. 循环 4-5 直到所有 task 完成
  └── 7. /commit 提交

赛后
  ├── 8. /security-scan 安全扫描
  ├── 9. 交叉测试
  ├── 10. 修复问题
  └── 11. /deploy 部署
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
