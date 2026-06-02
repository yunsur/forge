---
description: 一键部署项目
allowed-tools: Bash, Read
---

一键部署项目：

1. 检查是否有未提交的变更，如果有则停止并提示先提交
2. 检查当前分支：
   - 如果目标是生产环境（`$ARGUMENTS` 包含 "prod"），必须在 `main` 分支
3. 运行测试确保代码质量
4. 构建项目：
   - 如果有 `package.json`，运行 `npm run build`
   - 如果有 `Makefile`，运行 `make build`
5. 根据参数执行部署：
   - 如果提供了远程地址（如 `user@host:/path`），打包并传输
   - 否则，执行本地部署脚本（如果有）
6. 报告部署结果

参数格式：`/deploy [环境] [远程地址]`
- 环境：staging / prod（默认 staging）
- 远程地址：可选，如 `user@server:/app`
