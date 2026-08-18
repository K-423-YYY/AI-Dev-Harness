# AGENTS.md（harness 全局执行规则 v5.0）

## 项目结构
- core/run.bat / run.ps1 / run.sh：唯一入口（按平台选择）
- core/engine.ps1：执行循环与异常处理
- core/router.py：任务路由（PLAN/PLAN_DOC/TEST/EXEC + RUN_AS）
- adapters/：软件适配层（_detect 自动识别 + codex-cli / codex-cloud / deepseek-harness）
- skills/：可调用技能（frontend-design / webapp-testing / backend-api / spec）
- templates/：项目模板（video-downloader / iot-monitor）
- docs/plan.md：计划书（执行核心，首次运行自动生成，SDD 格式）
- docs/ARCHITECTURE.md：架构记忆（每完成一个子功能增量更新）
- docs/CHECKPOINTS.md：回滚检查点日志（每轮记录）
- docs/STATUS.md：异常停止时的状态报告
- scripts/verify.*：验证命令（install/lint/test/build/typecheck）
- scripts/spec-check.*：SDD 验收标准核对
- scripts/e2e.*：Playwright 浏览器自测
- scripts/setup-project.*：生成项目级省 token 规则
- scripts/update-skills.*：更新官方技能
- scripts/install-global.*：SCOPE=global 安装器
- scripts/selftest.*：冒烟自测
- sync/：GitHub 同步

## 工作流程（必须遵守）
1. 所有开发任务严格按 docs/plan.md 执行。
2. 若计划书不专业或不完整，先更新它再执行。
3. 使用 memory MCP 保存进度、关键决策，避免重复分析。
4. 优先使用 git diff 查看改动，不要全文读取文件。
5. 验证失败时只读取错误输出，修复后重跑验证。
6. 每轮执行完成后提交一次 Git 进度；项目无 Git 仓库时自动 git init，可用 AUTO_GIT_INIT=0 关闭。
7. 若某任务过大，先拆分为可单轮完成的小任务并更新 docs/plan.md，再执行。

## 方案先行（Plan-First）
- 任何需求启动前，必须由 Planner 角色输出规范方案（Spec Document）。
- PLAN_APPROVAL=1 时，方案未获得人类工程师显式确认（"APPROVED"）前，禁止调用编码工具。

## 角色纪律（职责单一化）
- Planner 角色：只做设计决策与计划/架构文档更新，不写业务代码。
- Coder 角色：只按 plan.md 实现/修复代码，不扩大范围。
- Tester 角色：只做验证、测试与缺陷定位，修复交下一轮。

## 上下文隔离与 Token 节省规则
- 每轮执行只允许引入 docs/plan.md、docs/ARCHITECTURE.md 以及当前涉及的源代码文件。
- 严禁全量载入项目不相关代码历史。

## 工具使用规范
- 遇到第三方 SDK 或框架 API 查询时，强制调用 Context7/Firecrawl MCP（已安装时）。
- 禁止凭空捏造 API，减少因语法报错重复耗费 Token 的尝试。

## 异常处理规则（N1）
- 每轮完成项无进展（连续 2 轮）或单轮超时（ROUND_TIMEOUT，默认 10 分钟）视为卡住。
- 执行循环最多 MAX_ROUNDS=5 轮，超限即停止。
- 遇到必须用户手动操作的地方，输出 NEED_HUMAN: <说明> 标记并停止，等待用户处理。

## 省 token 规则
- 不读 node_modules、dist、coverage、.git、venv、__pycache__。
- 大文件用 grep/head/tail 定位。
- 优先使用现有 skills 中的规范。

## 技能
- UI 相关：调用 frontend-design 技能
- 后端 API：调用 backend-api 技能
- Web 测试：调用 webapp-testing 技能
- 规范与验收：调用 spec 技能（spec-writer / spec-checker）
