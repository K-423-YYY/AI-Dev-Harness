# CHANGELOG

## v5.0（终极整合版）
- 整合 v2.0（合并完整方案）/ v3.0（单文件夹·作用域·简易化）/ v4.0（异常·适配·模块化）全部内容
- 新增：异常处理（MAX_ROUNDS=5、无进展/超时检测、NEED_HUMAN、状态报告）
- 新增：软件适配层 adapters/（Codex CLI / Codex Cloud / DeepSeek Harness + 自动识别 + 未适配不执行）
- 新增：模块化结构 core/adapters/skills/templates/docs/scripts/sync
- 保留：B 基座全部脚本（verify/setup-project/update-skills/github-sync）与官方技能

## v4.0（2026-08-16）
- 异常处理机制、软件适配与自动识别、模块化工程化、现有内容提取融合、纯净交付

## v3.0（2026-08-16）
- 单文件夹交付（AI-Dev-Harness/）、SCOPE 作用域三模式（local/global/off）、交互菜单、零配置启动

## v2.0（2026-08-16）
- AI Agent Harness（A）与 Codex 一键自动化工作流（B）合并完整方案：SDD 规范、角色化、三层验证、双轨记忆、省 token 八项

## v1.0（2026-08-15）
- 基座：基于 Codex 的一键自动化开发工作流（codex-workflow/ 单文件夹 + 单入口脚本）

## v5.1（2026-08）
- 新增：Claude Code 适配器（claude -p 非交互实测可用，本机 2.1.234）
- 新增：版本自检模块 core/version-check.ps1（零影响：只读提示、失败静默、不阻断执行）
- 修正：codex-cli 0.147.0 无 --remote（Codex Cloud 改登录态/配置识别）
- 修正：DSH 适配升级为 headless 真实执行 + 桥接兜底
- 修正：sync-to-github.ps1 兼容 PowerShell 5.1 stderr 警告（不再被 CRLF warning 终止）

