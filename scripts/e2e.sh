#!/usr/bin/env bash
# ============================================================
# e2e.sh - 浏览器端到端自测（bash 版）
# ============================================================
set -u
HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$(dirname "$HARNESS_ROOT")" || exit 1
source "$HARNESS_ROOT/adapters/_detect.sh"
ENGINE="$(detect_engine)"
if [ "$ENGINE" = "unsupported" ]; then echo "未适配引擎，跳过 e2e"; exit 1; fi

PROMPT="请使用 playwright MCP 对 frontend 执行核心流程自测（打开首页→登录→关键交互→退出）。任何一步失败，最后一行输出 E2E_FAIL；全部通过输出 E2E_PASS。"

if [ "$ENGINE" = "codex-cli" ] || [ "$ENGINE" = "codex-cloud" ]; then
  REMOTE=""; [ "$ENGINE" = "codex-cloud" ] && REMOTE="--remote"
  OUT=$(codex exec $REMOTE "$PROMPT" --sandbox workspace-write --skip-git-repo-check 2>/dev/null || true)
else
  echo "$PROMPT" > docs/exec-prompt.md
  echo "📄 E2E 指令已写入 docs/exec-prompt.md（DSH 桥接模式）"
  exit 0
fi
if echo "$OUT" | grep -q "E2E_PASS"; then echo "✅ e2e：核心流程自测通过"; exit 0; fi
echo "⚠️ e2e：自测失败"; exit 1
