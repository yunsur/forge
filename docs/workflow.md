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
$EDITOR config/project/tech-stack.md

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
> 比赛模式：实现一个文件上传功能，支持拖拽和点击，限制 10MB
```

Claude 会自动切换到比赛工作流。

---

## 2. Architect 规划（speckit plan → tasks）

Claude 会自动执行：

```bash
# 产出 plan 文件
speckit plan
# → docs/forge/file-upload/plan.md

# 产出 tasks 清单
speckit tasks
# → docs/forge/file-upload/tasks.md
```

你会看到类似输出：

```
## Tasks

- [ ] Task 1: 创建上传 API 端点
  - 验收标准: POST /api/upload 返回 200，文件存到 uploads/
- [ ] Task 2: 实现前端上传组件
  - 验收标准: 支持拖拽和点击，显示进度条
- [ ] Task 3: 添加文件大小校验
  - 验收标准: 超过 10MB 返回 413 错误
- [ ] Task 4: 添加文件类型校验
  - 验收标准: 只允许图片和 PDF
- [ ] Task 5: 编写测试
  - 验收标准: 覆盖所有 task 的验收标准
```

**确认 plan 后，开始实现。**

---

## 3. Developer 实现（逐 task TDD）

Claude 会按 tasks 清单逐个实现。每个 task 的流程：

```
Task 1: 创建上传 API 端点
├── 1. 读 task + 验收标准
├── 2. 写失败测试（TDD red）
├── 3. 写最小实现（TDD green）
├── 4. 标记完成
└── 5. 等待 tester 验证
```

你会看到：

```
📝 Task 1: 创建上传 API 端点
  🔴 写测试: test_upload_returns_200
  🟢 实现: POST /api/upload
  ✅ 测试通过
  📋 标记完成
```

---

## 4. Tester 验证（逐 task 验证）

每个 task 完成后，tester 立即验证：

```
🔍 验证 Task 1: 创建上传 API 端点
  ├── Scope Check: ✅ 只改了 routes/upload.ts
  ├── Functional: ✅ 测试通过
  ├── Plan Alignment: ✅ 符合 plan 意图
  └── Verdict: PASS → 继续下一个
```

如果失败：

```
🔍 验证 Task 2: 实现前端上传组件
  ├── Scope Check: ⚠️ 改了 utils.ts（不在 task 范围内）
  ├── Functional: ❌ 拖拽不工作
  ├── Verdict: FAIL
  └── → developer 修复
```

---

## 5. 循环直到完成

```
Task 1: ✅ architect → developer → tester → PASS
Task 2: ✅ architect → developer → tester → PASS
Task 3: ❌ architect → developer → tester → FAIL → 修复 → PASS
Task 4: ✅ architect → developer → tester → PASS
Task 5: ✅ architect → developer → tester → PASS
```

---

## 6. 提交代码

```bash
# 在 Claude Code 中
> /commit "feat(upload): implement file upload with drag-drop"
```

Claude 自动执行：
1. `git add -A`
2. 运行测试
3. `git commit -m "feat(upload): implement file upload with drag-drop"`

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
  ✅ 依赖安全: npm audit 通过
  ⚠️  SQL 注入: 发现 1 处（routes/upload.ts:42）
  → 修复后重扫
```

### 交叉测试

Claude 会作为 cross-tester 黑盒测试：

```
🔍 交叉测试
  ├── 用户流程: ✅ 上传成功
  ├── 边界测试: ✅ 空文件、超大文件、特殊字符
  ├── 集成测试: ✅ 前后端联调正常
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
  ├── 2. developer: 逐 task TDD 实现
  ├── 3. tester: 逐 task 即时验证
  ├── 4. 循环 2-3 直到所有 task 完成
  └── 5. /commit 提交

赛后
  ├── 6. /security-scan 安全扫描
  ├── 7. 交叉测试
  ├── 8. 修复问题
  └── 9. /deploy 部署
```

---

## 常见问题

### Q: 中途发现需要新功能怎么办？

```bash
# 告诉 architect 更新 plan
> architect: 需要加一个进度条功能，请更新 plan

# 不要自己加（会 drift）
```

### Q: tester 说 scope drift 怎么办？

```bash
# 回退无关改动
git checkout -- utils.ts

# 只保留 task 范围内的改动
```

### Q: 测试一直失败怎么办？

```bash
# 让 Claude 调试
> developer: task 3 的测试失败了，请调试

# 使用 systematic-debugging skill
```

### Q: 如何跳过某个 task？

```bash
# 告诉 architect 更新 plan
> architect: task 4 不做了，请从 tasks 中移除
```
