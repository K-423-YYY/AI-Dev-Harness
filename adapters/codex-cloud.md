# 适配方案：Codex Cloud（云端）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配方案二（N2）。

| 项 | 适配内容 |
|---|---|
| 检测 | `codex login status` 为 Cloud/远程；或 config.toml 含 `remote = true` / `model_provider = "cloud"` |
| 执行命令 | `codex exec --remote "指令" --skip-git-repo-check` |
| 登录态 | `codex login`（Cloud 账号）；`codex login status` 判定模式 |
| 规则加载 | AGENTS.md 同样生效（随项目上传） |
| 模型 | 云端模型（无需本地 config.toml 模型配置） |
| MCP | 云端支持的 MCP 或本地转发 |
| 超时控制 | 由 core/engine.ps1 的 Start-Process + WaitForExit 实现 |
| 特点 | 无需本地算力/密钥；需网络与 Cloud 订阅；sandbox 参数按 Cloud 模式调整 |

## 使用前提
1. 已安装 Codex CLI 并登录 **Codex Cloud** 账号。
2. 网络可用；有 Cloud 使用额度/订阅。

## 参数适配注意
- `--remote` 参数名随版本可能变化（`--cloud` 等），升级后先 `codex exec --help` 核对。
- 云端模式默认远程沙箱，`--sandbox workspace-write` 不需要（远程执行）。
