#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — 比赛时填写部署逻辑
# 用法: ./deploy.sh [环境] [远程地址]

ENV="${1:-staging}"
TARGET="${2:-}"

echo "🚀 部署到: $ENV"

# ============================================
# 比赛开始后填写以下内容
# ============================================

# 1. 检查未提交变更
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ 有未提交的变更，请先 commit"
  exit 1
fi

# 2. 运行测试
echo "🧪 运行测试..."
# docker compose -f docker-compose.test.yml run --rm backend pytest
# docker compose -f docker-compose.test.yml run --rm frontend pnpm test

# 3. 构建 & 部署
if [ -n "$TARGET" ]; then
  # 远程部署: 打包传到服务器
  echo "📦 打包..."
  tar czf /tmp/deploy.tar.gz --exclude='.git' --exclude='node_modules' --exclude='__pycache__' .
  echo "📤 传输到 $TARGET..."
  scp /tmp/deploy.tar.gz "$TARGET:/tmp/"
  ssh "${TARGET%%:*}" "
    cd /tmp && tar xzf deploy.tar.gz
    docker compose up -d --build
  "
else
  # 本地部署
  docker compose up -d --build
fi

echo "✅ 部署完成: $ENV"
