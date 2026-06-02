---
description: 一键安全扫描
allowed-tools: Bash, Read, Grep, Glob
---

一键安全扫描当前项目：

1. **敏感信息检查**
   - 搜索代码中的敏感模式：`password=`, `api_key=`, `secret=`, `token=`, `AWS_`, `PRIVATE KEY`
   - 排除 `.git/`, `node_modules/`, `test/`, `example/`
   - 报告发现的位置

2. **依赖安全检查**
   - 如果有 `package-lock.json`，运行 `npm audit --production`
   - 如果有 `requirements.txt`，运行 `pip audit`
   - 如果有 `Cargo.lock`，运行 `cargo audit`
   - 报告发现的漏洞

3. **敏感文件检查**
   - 搜索：`.env`, `.env.*`, `id_rsa`, `id_ed25519`, `*.pem`, `*.key`
   - 报告发现的敏感文件

4. **SQL 注入风险检查**
   - 搜索模式：`query.*+`, `execute.*+`（字符串拼接）
   - 报告潜在风险

5. **汇总报告**
   - 按严重性分类（Critical / High / Medium / Low）
   - 给出修复建议
   - 给出整体安全评估（PASS / WARN / FAIL）
