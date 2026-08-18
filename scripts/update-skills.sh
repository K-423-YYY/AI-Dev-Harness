#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="https://github.com/anthropics/skills"

echo "🔎 检测 GitHub 连通性..."
if ! git ls-remote --heads "$REPO_URL" HEAD >/dev/null 2>&1; then
  echo "⚠️ GitHub 不可达，保留本地技能版本。可稍后重试或配置代理。"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
git clone --depth 1 "$REPO_URL" "$TMP_DIR/skills" >/dev/null 2>&1

for skill in frontend-design backend-api webapp-testing; do
  if [ -d "$TMP_DIR/skills/$skill" ]; then
    cp -r "$TMP_DIR/skills/$skill/." "$WORKFLOW_DIR/skills/$skill/"
    echo "✅ 已更新 skills/$skill"
  else
    echo "ℹ️ 官方仓库无 $skill，保留本地版本"
  fi
done
