# ============================================================
# spec-check.ps1 - SDD 验收标准核对（N1/N3，方案 A 的验收校验落地）
# 调用引擎 + skills/spec/spec-checker.md 逐项核对验收标准
# 返回：0=通过 1=未通过
# ============================================================
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$WorkflowDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)   # ...\harness
$CoreDir = Join-Path $WorkflowDir 'core'
$ProjectRoot = Split-Path -Parent $WorkflowDir
Set-Location -LiteralPath $ProjectRoot

. (Join-Path $CoreDir 'engine.ps1')
. (Join-Path $WorkflowDir 'adapters\_detect.ps1')
Set-Engine (Get-Engine)

$planRel = 'docs/plan.md'
$prompt = "请调用 skills/spec/spec-checker.md 的方法，核对 $planRel 的全部验收标准与当前实现状态，输出核对报告并追加写入 docs/CHECKPOINTS.md。若存在未通过项，最后一行输出 SPEC_FAIL 并说明原因；全部通过输出 SPEC_PASS。"

if (Get-EngineName -eq 'deepseek-harness') {
  # DSH 桥接：写入指令文件
  $pf = Join-Path $ProjectRoot 'docs\exec-prompt.md'
  Set-Content -LiteralPath $pf -Value "# SDD 验收核对指令`n`n$prompt`n" -Encoding UTF8
  Write-Host "📄 验收核对指令已写入 docs/exec-prompt.md（DSH 桥接模式）"
  exit 0
}

$out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $ProjectRoot 'docs\.harness-log\spec-check') -TimeoutSec 600
if ($out -match 'SPEC_FAIL') { Write-Host '⚠️ spec-check：存在未通过项'; exit 1 }
if ($out -match 'SPEC_PASS') { Write-Host '✅ spec-check：验收标准全部通过'; exit 0 }
Write-Host '⚠️ spec-check：无法确认验收结果（未检测到 SPEC_PASS/SPEC_FAIL），按未通过处理'
exit 1
