#!/usr/bin/env bash
# ============================================================
# _detect.sh - 软件自动识别（N2，bash 版）
# 用法: source adapters/_detect.sh; detect_engine
# ============================================================

detect_engine() {
  if [ -n "${ENGINE:-}" ]; then
    case "$ENGINE" in
      codex-cli|codex-cloud|deepseek-harness) echo "$ENGINE"; return 0 ;;
      *) echo "⚠️ 未知 ENGINE=$ENGINE，回退自动检测" >&2 ;;
    esac
  fi
  if command -v codex >/dev/null 2>&1; then
    CODX_HOME="${CODEX_HOME:-$HOME/.codex}"
    if [ -f "$CODX_HOME/config.toml" ] && grep -qiE 'remote\s*=\s*true|cloud|model_provider\s*=\s*"?cloud' "$CODX_HOME/config.toml"; then
      echo "codex-cloud"
    else
      echo "codex-cli"
    fi
    return 0
  fi
  if [ -n "${DSH_HOME:-}" ] || command -v dsh >/dev/null 2>&1 || [ -d "$HOME/.dsh" ]; then
    echo "deepseek-harness"
    return 0
  fi
  echo "unsupported"
}
