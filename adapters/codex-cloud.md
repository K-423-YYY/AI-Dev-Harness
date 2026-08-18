# 适配方案：Codex Cloud（云端）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配方案二（N2）。
> ⚠️ **版本适配（2026-08 实测 codex-cli 0.147.0）**：`codex exec` **没有 `--remote` 参数**（早期版本/部分文档中的写法在当前版本不存在）。Cloud 的正确用法见下表。

| 项 | 适配内容 |
|---|---|
| 检测 | `config.toml` 中 `model_provider = "chatgpt"/"cloud"/"openai"`，或 `remote = true`；或 `codex login status` 为 ChatGPT 账号登录 |
| 执行命令 | `codex exec "指令" --sandbox workspace-write --skip-git-repo-check`（**与 codex-cli 相同**——Cloud 模式下 exec 自动使用云端模型，无需额外标志） |
| 登录态 | `codex login`（用 **ChatGPT 账号**登录，不是 API key）；`codex login status` 查看 |
| 规则加载 | AGENTS.md 同样生效（随项目上传） |
| 模型 | 云端模型（登录 ChatGPT 账号后由 Codex 决定，如 o3 / gpt-5-codex 等）；如需指定：`codex exec -m <模型> "指令"` |
| MCP | 云端支持的 MCP 或本地转发 |
| 实验性命令 | 0.147.0 提供 `codex cloud`（浏览 Codex Cloud 任务并本地应用变更）、`codex remote-control`（app-server daemon），均为 EXPERIMENTAL，不建议作为自动化主通道 |

## 使用前提
1. 已安装 Codex CLI 并**用 ChatGPT 账号登录**（`codex login`），而非仅 API key。
2. `~/.codex/config.toml` 中 `model_provider` 指向云端（chatgpt/openai），或直接依赖登录态默认云端。
3. 网络可用；有 Cloud 使用额度/订阅。

## 参数适配注意
- **没有 `--remote`**：请在升级 Codex 后运行 `codex exec --help` 核对（若未来版本新增远程标志，仅需更新 `core/engine.ps1` 的 `Get-ExecCommandLine` 与本文档）。
- 当前用户如果只用 API key 登录（`Logged in using an API key`），属于 **codex-cli（本地/自定义 provider）** 模式，不是 Cloud。
