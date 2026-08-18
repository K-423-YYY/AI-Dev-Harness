#!/usr/bin/env bash
set -euo pipefail

# 在目标项目根目录生成省 token 规则与分层 AGENTS.md，已存在的文件不覆盖。
PROJECT_ROOT="$(pwd)"

write_agents() {
  local path="$1"
  local extra="$2"
  if [ -f "$path" ]; then
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
# AGENTS.md（由 codex-workflow 自动生成，可自行修改）

## 规则
- 开发任务严格按 codex-workflow/docs/plan.md 执行。
- 不读取 node_modules、dist、coverage、.git、venv、__pycache__。
- 大文件用 grep/head/tail 定位，优先使用 git diff 查看改动。
- UI 相关调用 codex-workflow/skills/frontend-design，后端 API 调用 backend-api，Web 测试调用 webapp-testing。
$extra
EOF
  echo "✅ 已生成 $path"
}

write_agents "$PROJECT_ROOT/AGENTS.md" ""
if [ -d "$PROJECT_ROOT/frontend" ]; then
  write_agents "$PROJECT_ROOT/frontend/AGENTS.md" "- 前端改动保持与 frontend-design 技能一致。"
fi
if [ -d "$PROJECT_ROOT/backend" ]; then
  write_agents "$PROJECT_ROOT/backend/AGENTS.md" "- 后端改动保持与 backend-api 技能一致。"
fi
