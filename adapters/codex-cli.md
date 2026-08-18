# 适配方案：Codex CLI（本地客户端）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配方案一（N2）。

| 项 | 适配内容 |
|---|---|
| 检测 | 存在 `codex` 命令且 `~/.codex/config.toml` 配置了本地模型（非 remote/cloud） |
| 执行命令 | `codex exec "指令" --sandbox workspace-write --skip-git-repo-check` |
| 规则加载 | AGENTS.md（Codex 自动加载） |
| 模型识别 | 读 `~/.codex/config.toml` 的 model / model_provider |
| MCP | `codex mcp add memory` / `codex mcp add playwright` / `codex mcp add firecrawl` / `codex mcp add context7` |
| 技能 | 自动读取 harness/skills/ 目录 |
| 超时控制 | 由 core/engine.ps1 的 Start-Process + WaitForExit 实现 |
| 特点 | 本地或第三方模型（如 DeepSeek）经 config.toml 接入；离线可用 |

## 使用前提
1. 已安装 Codex CLI 并登录。
2. `~/.codex/config.toml` 配置好 model 与 model_provider（示例：`model = "deepseek-chat"`、`model_provider = "deepseek"` + provider 定义 + `env_key = "DEEPSEEK_API_KEY"`）。

## 参数适配注意
- 新版 Codex CLI 已移除 `--max-turns`、`--full-auto`、`codex config get model`；本适配统一使用 `--sandbox workspace-write --skip-git-repo-check`。
- 升级 CLI 后如遇参数报错，先运行 `codex exec --help` 核对。
