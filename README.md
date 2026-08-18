# AI-Dev-Harness 一键全栈开发引擎（v5.1）

一个**自包含单文件夹**的 AI 开发引擎：复制到任意项目文件夹，启动后**自动识别当前 AI 软件**（Codex CLI / Codex Cloud / Claude Code / DeepSeek Harness），按 SDD 计划书自动完成"计划 → 开发 → 验证 → 修复 → 记忆 → 提交"闭环。

## 三步使用

```
第 1 步：把整个 AI-Dev-Harness 文件夹复制到项目根目录（没有项目就新建一个空文件夹）
第 2 步：启动
        Windows：双击 AI-Dev-Harness\core\run.bat
        或终端：  .\AI-Dev-Harness\core\run.bat "你的项目目标"
        Linux/macOS：./AI-Dev-Harness/core/run.sh "你的项目目标"
第 3 步：首次运行生成计划书（项目/docs/plan.md），确认后再次运行同一命令自动开发
```

## 三个常用开关

| 开关 | 作用 | 示例 |
|---|---|---|
| `SCOPE` | local=仅当前项目文件夹（默认）/ global=全局安装 / off=零写入预览 | `SCOPE=off .\AI-Dev-Harness\core\run.bat "目标"` |
| `ENGINE` | 显式指定引擎：codex-cli / codex-cloud / claude-code / deepseek-harness | `ENGINE=claude-code …` |
| `MAX_ROUNDS` | 最大执行轮次（默认 5，异常保护） | `MAX_ROUNDS=10 …` |

## 支持的 AI 软件（自动识别，未适配不执行）

| 引擎 | 识别 | 适配方案 |
|---|---|---|
| **Codex CLI**（本地客户端） | `codex` 命令 + 本地/自定义 provider | `adapters/codex-cli.md` |
| **Codex Cloud**（云端） | `codex` 命令 + ChatGPT 账号登录 / cloud provider | `adapters/codex-cloud.md` |
| **Claude Code**（Anthropic 官方） | `claude` 命令 | `adapters/claude-code.md` |
| **DeepSeek Harness**（DSH） | `dsh` 命令 / DSH 环境 | `adapters/deepseek-harness.md` |

> 版本自检：每次启动自动核对引擎版本与内置"已知兼容版本"清单，不匹配时仅输出 ℹ️ 提示（**零影响**：不改任何配置、不阻断执行、失败静默）。清单维护于 `core/version-check.ps1`。

## 目录结构

```
AI-Dev-Harness/
├── core/          引擎（run 入口 · engine 循环/异常 · status 报告 · router 路由 · version-check 版本自检 · AGENTS.md）
├── adapters/      软件适配（_detect 自动识别 + codex-cli · codex-cloud · claude-code · deepseek-harness + 扩展模板）
├── skills/        技能（frontend-design · webapp-testing · backend-api · spec/SDD）
├── templates/     项目模板（video-downloader · iot-monitor）
├── docs/          文档模板（plan.example · ARCHITECTURE.example · CHECKPOINTS.example）
├── scripts/       辅助脚本（verify · spec-check · e2e · setup-project · update-skills · install-global · selftest）
└── sync/          GitHub 同步
```

## 常见操作

```bat
.\AI-Dev-Harness\core\run.bat "修改计划：增加XX模块"      :: 修改计划书
.\AI-Dev-Harness\scripts\selftest.ps1                    :: 冒烟自测
.\AI-Dev-Harness\sync\sync-to-github.ps1 "更新说明"       :: 同步 GitHub
```

## 版本适配注记（2026-08 实测）

- **codex-cli 0.147.0**：`codex exec --sandbox workspace-write --skip-git-repo-check` 可用；**无 `--remote`**；`--max-turns`/`--full-auto` 已移除。
- **codex-cloud**：当前版本 Cloud 由 ChatGPT 账号登录 + `model_provider="chatgpt"` 决定，`exec` 无 `--remote`。
- **claude-code 2.1.234**：`claude -p "指令" --output-format text --dangerously-skip-permissions` 非交互实测可用。
- **dsh 0.1.0-rc.6**：`dsh --profile headless "任务"` 真实执行，失败回落桥接模式。

详细使用见《使用手册（傻瓜版）.md》。
