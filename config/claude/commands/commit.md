---
description: 一键提交代码（lint + test + commit）
allowed-tools: Bash, Read, Edit
---

一键提交当前变更：

1. 检查是否有未提交的变更（`git status`）
2. 如果没有变更，提示用户并停止
3. 暂存所有变更（`git add -A`）
4. 运行项目测试：
   - 如果有 `package.json`，运行 `npm test`
   - 如果有 `tests/` 目录，运行 `pytest -q`
   - 如果有 `Cargo.toml`，运行 `cargo test`
5. 如果测试失败，停止并报告错误
6. 如果测试通过，用用户提供的提交信息提交（`git commit -m "$ARGUMENTS"`）
7. 显示提交结果（`git log --oneline -1`）

提交信息格式：`type(scope): subject`
- type: feat / fix / docs / style / refactor / test / chore
- scope: 可选，影响范围
- subject: 简短描述，不超过 72 字符
