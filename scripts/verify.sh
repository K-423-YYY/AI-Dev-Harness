#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(pwd)"

run_project_checks() {
  local dir="$1"
  if [ ! -d "$dir" ] || [ ! -f "$dir/package.json" ]; then
    return 0
  fi

  echo "🔎 验证 $dir ..."
  cd "$dir"

  local pkg_manager="pnpm"
  if ! command -v pnpm >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
      pkg_manager="npm"
    elif command -v yarn >/dev/null 2>&1; then
      pkg_manager="yarn"
    else
      echo "⚠️ 未找到 pnpm/npm/yarn，跳过 $dir 验证" >&2
      cd "$PROJECT_ROOT"
      return 0
    fi
  fi

  "$pkg_manager" install --silent
  "$pkg_manager" lint
  "$pkg_manager" test
  "$pkg_manager" build
  "$pkg_manager" typecheck
  cd "$PROJECT_ROOT"
}

run_project_checks frontend
run_project_checks backend

echo "✅ 验证通过"
