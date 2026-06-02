#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — 比赛时填写部署逻辑
# 用法: ./deploy.sh [环境]

ENV="${1:-staging}"

echo "🚀 部署到: $ENV"

# ============================================
# 比赛开始后填写以下内容
# ============================================

# 示例 1: SSH 部署
# TARGET="user@server:/app"
# tar czf /tmp/deploy.tar.gz --exclude='.git' --exclude='node_modules' .
# scp /tmp/deploy.tar.gz "$TARGET:/tmp/"
# ssh "${TARGET%%:*}" "cd /tmp && tar xzf deploy.tar.gz"

# 示例 2: Docker 部署
# docker build -t myapp .
# docker push myapp:latest
# ssh user@server "docker pull myapp:latest && docker-compose up -d"

# 示例 3: Vercel/Netlify 部署
# npx vercel --prod

# 示例 4: 静态文件部署
# rsync -avz ./dist/ user@server:/var/www/html/

# ============================================

echo "✅ 部署完成"
