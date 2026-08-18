# 适配方案：DeepSeek Harness（DSH）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配方案三（N2）。
> ✅ **版本适配（2026-08 实测 dsh CLI）**：`dsh --profile headless "任务"` 可"回答一个任务、打印结果、退出"——已作为 DSH 的真实执行通道。

| 项 | 适配内容 |
|---|---|
| 检测 | 存在 DSH 环境（`dsh` 命令 / `$env:DSH_*` / `~/.dsh` 目录） |
| 执行方式 A（真实执行，优先） | `dsh --profile headless "指令"`——单任务回答并退出，作为引擎的 AI 执行通道；由 `core/engine.ps1` 的 `Invoke-EngineExec` 调用，headless 不可用（dsh 缺失/失败）时自动回落方式 B |
| 执行方式 B（桥接兜底） | 把本轮执行指令写入 `docs/exec-prompt.md`，由 DSH 中的 AI（agent）读取并执行；完成后更新 plan.md、运行验证，用户重跑 harness 续接 |
| 执行方式 C（插件化） | 把工作流注册为 DSH 动态插件（cordis plugin），以 DSH 原生工具（read/write/edit/pwsh）执行（高级，可选） |
| 规则加载 | 项目 AGENTS.md 作为会话指令注入 |
| 模型 | 由 DSH 配置决定（DeepSeek 等） |
| 特点 | 本地运行、模型路由可配、与 DSH 沙箱/审批机制集成 |

## 使用前提
1. 已安装 DSH CLI（npm 全局 `@deepseek-ai/dsh`，命令 `dsh`）。
2. DSH 配置文件就绪（`~/.dsh/`，含模型路由配置）。
3. headless 模式在受限环境（如沙箱）可能因无法写 `~/.dsh` 配置而失败——此时引擎自动回落桥接模式。

## 桥接模式工作流程（方式 B）
1. `run.bat "目标"` → 检测到 DSH → 尝试 headless；失败则生成计划书提示（写入 `docs/exec-prompt.md`）。
2. 用户把 `docs/exec-prompt.md` 内容交给 DSH 中的 AI 执行。
3. AI 执行完（更新 plan.md 勾选、写 ARCHITECTURE/CHECKPOINTS）后，重跑 harness → 自动验证、Git 提交、进入下一轮或完成。
