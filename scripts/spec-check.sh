#!/usr/bin/env bash
# ============================================================
# spec-check.sh - SDD 验收标准核对（bash 版）
# ============================================================
set -u
HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$(dirname "$HARNESS_ROOT")" || exit 1
source "$HARNESS_ROOT/adapters/_detect.sh"
ENGINE="$(detect_engine)"
if [ "$ENGINE" = "unsupported" ]; then echo "未适配引擎，跳过 spec-check"; exit 1; fi

PROMPT="请调用 skills/spec/spec-checker.md 的方法，核对 docs/plan.md 的全部验收标准，输出核对报告并追加写入 docs/CHECKPOINTS.md。若存在未通过项，最后一行输出 SPEC_FAIL；全部通过输出 SPEC_PASS。"

if [ "$ENGINE" = "codex-cli" ] || [ "$ENGINE" = "codex-cloud" ]; then
  REMOTE=""; [ "$ENGINE" = "codex-cloud" ] && REMOTE="--remote"
  OUT=$(codex exec $REMOTE "$PROMPT" --sandbox workspace-write --skip-git-repo-check 2>/dev/null || true)
else
  echo "$PROMPT" > docs/exec-prompt.md
  echo "📄 验收核对指令已写入 docs/exec-prompt.md（DSH 桥接模式）"
  exit 0
fi
if echo "$OUT" | grep -q "SPEC_FAIL"; then echo "⚠️ spec-check：存在未通过项"; exit 1; fi
if echo "$OUT" | grep -q "SPEC_PASS"; then echo "✅ spec-check：验收标准全部通过"; exit 0; fi
echo "⚠️ spec-check：无法确认验收结果"; exit 1
