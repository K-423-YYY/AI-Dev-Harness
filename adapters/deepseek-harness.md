# 适配方案：DeepSeek Harness（DSH）

> 对应《终极方案与需求理念（整合版 v5.0）》第三部分 §3.2 适配方案三（N2）。

| 项 | 适配内容 |
|---|---|
| 检测 | 存在 DSH 环境（`$env:DSH_*` 变量 / `dsh` 命令 / `~/.dsh` 目录） |
| 执行方式 A（默认桥接） | harness 将本轮执行指令写入 `docs/exec-prompt.md`，由 DSH 中的 AI（agent）读取并执行；AI 完成后更新 plan.md 勾选、运行验证脚本；用户重跑 harness 续接 |
| 执行方式 B（插件化） | 把工作流注册为 DSH 动态插件（cordis plugin），以 DSH 原生工具（read/write/edit/pwsh）执行验证与文件操作 |
| 规则加载 | 项目 AGENTS.md 作为会话指令注入 |
| 模型 | 由 DSH 配置决定（DeepSeek 等） |
| 特点 | 本地运行、模型路由可配、与 DSH 沙箱/审批机制集成 |

## 使用前提
1. 当前处于 DeepSeek Harness 环境（或在安装了 DSH 的机器上）。
2. 桥接模式下无需额外安装；插件模式需 DSH 插件机制支持。

## 桥接模式工作流程
1. `run.bat "目标"` → 检测到 DSH → 生成计划书到 `docs/plan.md`（写入 `docs/exec-prompt.md` 提示 DSH 生成）。
2. 用户把 `docs/exec-prompt.md` 内容交给 DSH 中的 AI 执行。
3. AI 执行完（更新 plan.md 勾选、写 ARCHITECTURE/CHECKPOINTS）后，重跑 harness → 自动验证、Git 提交、进入下一轮或完成。
