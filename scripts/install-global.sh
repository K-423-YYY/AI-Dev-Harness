#!/usr/bin/env bash
# ============================================================
# install-global.sh - SCOPE=global 全局安装器（bash 版）
# ============================================================
set -euo pipefail
HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_SKILLS="$HOME/.codex/skills"
GLOBAL_BIN="$HOME/.codex/bin"

echo "🌐 全局安装将执行以下写入（均可通过 SCOPE=off 还原/关闭）："
echo "  1) 复制技能到：$GLOBAL_SKILLS"
echo "  2) 注册全局命令：$GLOBAL_BIN/harness.sh"
read -r -p "确认执行全局安装？输入 YES 继续: " CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "已取消。"; exit 0; }

mkdir -p "$GLOBAL_SKILLS" "$GLOBAL_BIN"
for s in frontend-design webapp-testing backend-api spec; do
  if [ -d "$HARNESS_ROOT/skills/$s" ]; then
    cp -r "$HARNESS_ROOT/skills/$s" "$GLOBAL_SKILLS/$s"
    echo "✅ 已复制 skills/$s"
  fi
done

cat > "$GLOBAL_BIN/harness.sh" <<EOF
#!/usr/bin/env bash
exec "$HARNESS_ROOT/core/run.sh" "\$@"
EOF
chmod +x "$GLOBAL_BIN/harness.sh"
echo "✅ 已注册全局命令：$GLOBAL_BIN/harness.sh"
echo "   使用：$GLOBAL_BIN/harness.sh \"目标\"（可加入 PATH）"
echo "🎉 全局安装完成。关闭影响：SCOPE=off"
