#!/usr/bin/env bash
# ============================================================
# run.sh - Codex Harness 一键全栈开发引擎 Linux/macOS 入口（v5.0）
# 用法: ./harness/core/run.sh "你的项目目标"
# ============================================================
set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="$(dirname "$WORKFLOW_DIR")"
PROJECT_ROOT="$(dirname "$HARNESS_ROOT")"
cd "$PROJECT_ROOT"

# ---------- 软件自动识别（N2）----------
ENGINE="${ENGINE:-}"
if [ -z "$ENGINE" ]; then
  if command -v codex >/dev/null 2>&1; then
    ENGINE="codex-cli"
  elif [ -n "${DSH_HOME:-}" ] || command -v dsh >/dev/null 2>&1 || [ -d "$HOME/.dsh" ]; then
    ENGINE="deepseek-harness"
  else
    ENGINE="unsupported"
  fi
fi
echo "🔍 识别引擎：$ENGINE"

if [ "$ENGINE" = "unsupported" ]; then
  echo "❌ 当前环境未适配 Codex Harness 工作流。"
  echo "   支持列表：Codex CLI / Codex Cloud / DeepSeek Harness"
  echo "   请安装其一，或设置 ENGINE=codex-cli|codex-cloud|deepseek-harness 显式指定。"
  exit 1
fi

# ---------- 作用域（v3.0）----------
SCOPE="${SCOPE:-local}"
if [ "$SCOPE" = "off" ]; then
  echo "🔕 SCOPE=off：零写入零修改（只读预览模式）。"
  echo "   将执行的动作预览：生成计划、循环执行（最多 ${MAX_ROUNDS:-5} 轮）、验证、Git 提交。"
  exit 0
fi
if [ "$SCOPE" = "global" ]; then
  echo "🌐 SCOPE=global：请运行 scripts/install-global.sh"
  exit 0
fi

# ---------- 输入 ----------
INPUT="${*:-}"
if [ -z "$INPUT" ]; then
  echo "用法: ./harness/core/run.sh <目标或指令>"
  exit 1
fi

DOCS_DIR="$PROJECT_ROOT/docs"
PLAN_FILE="$DOCS_DIR/plan.md"
mkdir -p "$DOCS_DIR"

# 修改计划
if [[ "$INPUT" == *"修改计划"* || "$INPUT" == *"编辑计划"* || "$INPUT" == *"更新计划"* ]]; then
  echo "📝 检测到计划书修改请求，直接更新 docs/plan.md"
  if [ "$ENGINE" = "codex-cli" ]; then
    codex exec "请根据以下要求修改计划书：$INPUT。按 SDD 格式编辑 docs/plan.md，不要编写其他代码。" \
      --sandbox workspace-write --skip-git-repo-check || true
  else
    echo "桥接模式：将修改指令写入 docs/exec-prompt.md 后交由 DSH 中的 AI 执行。"
    echo "请根据以下要求修改计划书：$INPUT。按 SDD 格式编辑 docs/plan.md，不要编写其他代码。" > "$DOCS_DIR/exec-prompt.md"
  fi
  exit 0
fi

# 生成计划
if [ ! -f "$PLAN_FILE" ]; then
  echo "📋 未找到计划书，自动根据目标生成计划..."
  if [ "$ENGINE" = "codex-cli" ]; then
    codex exec "请调用 skills/spec/spec-writer.md 的方法，根据目标「$INPUT」生成专业开发计划，保存到 docs/plan.md。必须包含：目标、需求补全、任务分解表、验收标准、验证方式。不要写代码。" \
      --sandbox workspace-write --skip-git-repo-check || true
  else
    echo "请调用 skills/spec/spec-writer.md 的方法，根据目标「$INPUT」生成专业开发计划，保存到 docs/plan.md。" > "$DOCS_DIR/exec-prompt.md"
  fi
  echo "✅ 计划已生成：$PLAN_FILE（或已写入 docs/exec-prompt.md 待 DSH 执行）"
  exit 0
fi

# ---------- 执行循环（N1：最多 5 轮）----------
echo "🚀 开始自动执行计划：docs/plan.md（最多 ${MAX_ROUNDS:-5} 轮）"
MAX_ROUNDS="${MAX_ROUNDS:-5}"
for i in $(seq 1 "$MAX_ROUNDS"); do
  echo "🔄 第 $i 轮执行"
  if [ "$ENGINE" = "codex-cli" ]; then
    codex exec "请严格按照 docs/plan.md 执行。使用 memory MCP 记录进度；每完成一个子功能：更新 docs/plan.md 勾选 → 增量追加 docs/ARCHITECTURE.md → 写入 docs/CHECKPOINTS.md；运行 scripts/verify.sh 验证，失败则修复。若所有任务已完成，报告完成。若遇到必须用户手动操作的地方，输出 NEED_HUMAN: <说明> 并停止。" \
      --sandbox workspace-write --skip-git-repo-check || true
  else
    echo "请严格按照 docs/plan.md 执行。使用 memory MCP 记录进度；每完成一个子功能：更新 docs/plan.md 勾选 → 增量追加 docs/ARCHITECTURE.md → 写入 docs/CHECKPOINTS.md；运行 scripts/verify.sh 验证，失败则修复。若所有任务已完成，报告完成。若遇到必须用户手动操作的地方，输出 NEED_HUMAN: <说明> 并停止。" > "$DOCS_DIR/exec-prompt.md"
  fi

  # NEED_HUMAN 检测
  if grep -q "NEED_HUMAN" "$DOCS_DIR/exec-prompt.md" 2>/dev/null; then
    echo "⚠️ 需要人工操作，已停止。请按 docs/exec-prompt.md 指引处理后重跑。"
    exit 0
  fi

  # Git 提交
  if command -v git >/dev/null 2>&1 && [ "${AUTO_GIT_INIT:-1}" != "0" ]; then
    git add -A 2>/dev/null || true
    git commit -m "harness: 第 $i 轮执行进度" 2>/dev/null || true
  fi

  # 验证
  if [ -f "$HARNESS_ROOT/scripts/verify.sh" ] && bash "$HARNESS_ROOT/scripts/verify.sh"; then
    echo "✅ 验证通过，检查是否全部完成..."
    if [ "$ENGINE" = "codex-cli" ]; then
      OUT=$(codex exec "请检查 docs/plan.md 中的任务是否全部标记完成。若全部完成，只输出 ALL_DONE。" \
        --sandbox workspace-write --skip-git-repo-check 2>/dev/null || true)
      if echo "$OUT" | grep -q "ALL_DONE"; then echo "🎉 项目完成！"; exit 0; fi
    else
      echo "桥接模式：请检查 docs/plan.md 是否全部完成，若完成输出 ALL_DONE。"
    fi
  else
    echo "⚠️ 验证失败，继续下一轮修复"
  fi
done

echo "⏹️ 达到最大轮次（$MAX_ROUNDS），请查看 docs/STATUS.md（或 docs/exec-prompt.md）与项目状态。"
exit 1
