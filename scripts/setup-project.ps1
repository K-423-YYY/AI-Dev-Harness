[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Get-Location).Path

function Write-AgentsFile {
  param(
    [string]$Path,
    [string]$Extra
  )
  if (Test-Path -LiteralPath $Path) { return }
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  $content = @"
# AGENTS.md（由 codex-workflow 自动生成，可自行修改）

## 规则
- 开发任务严格按 codex-workflow/docs/plan.md 执行。
- 不读取 node_modules、dist、coverage、.git、venv、__pycache__。
- 大文件用 grep/head/tail 定位，优先使用 git diff 查看改动。
- UI 相关调用 codex-workflow/skills/frontend-design，后端 API 调用 backend-api，Web 测试调用 webapp-testing。
$Extra
"@
  Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
  Write-Host "✅ 已生成 $Path"
}

Write-AgentsFile -Path (Join-Path $ProjectRoot 'AGENTS.md') -Extra ''
if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'frontend')) {
  Write-AgentsFile -Path (Join-Path $ProjectRoot 'frontend\AGENTS.md') -Extra '- 前端改动保持与 frontend-design 技能一致。'
}
if (Test-Path -LiteralPath (Join-Path $ProjectRoot 'backend')) {
  Write-AgentsFile -Path (Join-Path $ProjectRoot 'backend\AGENTS.md') -Extra '- 后端改动保持与 backend-api 技能一致。'
}
