#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cp -r "$WORKFLOW_DIR" "$TMP_DIR/codex-workflow"

cat > "$TMP_DIR/bin/codex" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "config" ] && [ "$2" = "get" ]; then echo stub-model; exit 0; fi
if [ "$1" = "mcp" ] && [ "$2" = "list" ]; then echo memory; echo playwright; exit 0; fi
if [ "$1" = "exec" ]; then echo ALL_DONE; exit 0; fi
exit 0
EOF
chmod +x "$TMP_DIR/bin/codex"
export PATH="$TMP_DIR/bin:$PATH"
export AUTO_GIT_INIT=0

if ! bash "$TMP_DIR/codex-workflow/run.sh" "测试目标"; then
  echo "❌ 生成计划路径失败" >&2
  exit 1
fi
printf '# 测试计划\n- [ ] 任务1\n' > "$TMP_DIR/codex-workflow/docs/plan.md"
if ! bash "$TMP_DIR/codex-workflow/run.sh" "测试目标"; then
  echo "❌ 执行路径失败" >&2
  exit 1
fi
if ! bash "$TMP_DIR/codex-workflow/run.sh" "修改计划：增加测试模块"; then
  echo "❌ 修改计划路径失败" >&2
  exit 1
fi
echo "✅ selftest 通过"
