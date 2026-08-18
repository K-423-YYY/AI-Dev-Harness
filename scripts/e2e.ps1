# ============================================================
# e2e.ps1 - 浏览器端到端自测（方案 A 的 Tester Agent 浏览器自测落地）
# 依赖 Playwright MCP（B 基座自动安装）
# 返回：0=通过 1=失败
# ============================================================
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$WorkflowDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$CoreDir = Join-Path $WorkflowDir 'core'
$ProjectRoot = Split-Path -Parent $WorkflowDir
Set-Location -LiteralPath $ProjectRoot

. (Join-Path $CoreDir 'engine.ps1')
. (Join-Path $WorkflowDir 'adapters\_detect.ps1')
Set-Engine (Get-Engine)

$prompt = "请使用 playwright MCP 对 frontend 执行核心流程自测（打开首页→登录→关键交互→退出）。记录结果。任何一步失败，最后一行输出 E2E_FAIL 并说明失败原因；全部通过输出 E2E_PASS。"

if (Get-EngineName -eq 'deepseek-harness') {
  $pf = Join-Path $ProjectRoot 'docs\exec-prompt.md'
  Set-Content -LiteralPath $pf -Value "# E2E 自测指令`n`n$prompt`n" -Encoding UTF8
  Write-Host "📄 E2E 指令已写入 docs/exec-prompt.md（DSH 桥接模式）"
  exit 0
}

$out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $ProjectRoot 'docs\.harness-log\e2e') -TimeoutSec 900
if ($out -match 'E2E_PASS') { Write-Host '✅ e2e：核心流程自测通过'; exit 0 }
Write-Host '⚠️ e2e：自测失败（或未检测到 E2E_PASS）'
exit 1
