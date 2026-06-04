---
description: 一键本地部署项目
allowed-tools: Bash, Read
---

一键本地部署项目：

1. 检查是否有未提交的变更，如果有则停止并提示先提交
2. 运行测试确保代码质量
3. 启动 Docker 服务：`docker compose up -d --build`
4. 报告部署结果
