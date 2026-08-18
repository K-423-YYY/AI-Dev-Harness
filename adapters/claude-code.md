# 适配方案：Claude Code（Anthropic CLI）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配（N2）。
> ✅ **版本适配（2026-08 实测 Claude Code 2.1.234）**：`claude -p "指令" --output-format text` 可非交互执行并返回结果，已在本机实测通过（约 5 秒返回）。

| 项 | 适配内容 |
|---|---|
| 检测 | 存在 `claude` 命令（npm 全局 `@anthropic-ai/claude-code`） |
| 执行命令 | `claude -p "指令" --output-format text --dangerously-skip-permissions` |
| 规则加载 | **CLAUDE.md**（Claude Code 的规则文件，与 AGENTS.md 等价；harness 的 AGENTS.md 内容可复制为 CLAUDE.md 或在提示词中引用） |
| 模型 | 由 Claude Code 配置/账号决定；可用 `-m/--model <模型>` 或 `--fallback-model <模型>` 指定 |
| 系统提示 | 可用 `--append-system-prompt "..."` 追加（如注入 harness 角色规则） |
| MCP | 支持 MCP：`claude mcp add` 或配置文件中挂载 |
| 权限 | `--dangerously-skip-permissions` 跳过全部权限确认（自动化必需；与 codex 的 bypass 同理，注意安全边界） |
| 超时控制 | 由 core/engine.ps1 的 Invoke-EngineExec 统一处理 |
| 特点 | 官方非交互（print）模式成熟、速度快；同一台机器可与 Codex/DSH 并存 |

## 使用前提
1. 已安装 Claude Code：`npm install -g @anthropic-ai/claude-code`
2. 已登录/配置：`claude` 首次运行登录（Anthropic 账号或 API key），或设置 `ANTHROPIC_API_KEY`。
3. 注意：若终端显示 `[claude-code:unrecognized_model]` 警告（如经第三方工具转发模型名），通常不影响执行，可忽略；如需彻底消除，请在 Claude Code 配置中修正模型名。

## 参数适配注意
- `-p` 即 `--print`（非交互）；`--output-format text` 输出纯文本（默认是 JSONL 事件流）。
- 权限参数随版本可能变化：2.x 支持 `--dangerously-skip-permissions` 与 `--allow-dangerously-skip-permissions`；升级后先 `claude --help` 核对。
- 规则文件：本项目使用 AGENTS.md；若主要用 Claude Code，可另建 CLAUDE.md 或在 `core/engine.ps1` 的 claude 分支提示词中注入规则。
