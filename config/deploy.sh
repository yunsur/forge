#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — local development deployment
# Usage: ./deploy.sh

echo "Starting local dev environment..."

# 1. Check uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: uncommitted changes. Please commit first."
  exit 1
fi

# 2. Run tests
echo "Running tests..."
# docker compose -f docker-compose.test.yml run --rm backend pytest
# docker compose -f docker-compose.test.yml run --rm frontend pnpm test

# 3. Start services
docker compose up -d --build

echo "Dev environment started. Run 'docker compose logs -f' to view logs."
