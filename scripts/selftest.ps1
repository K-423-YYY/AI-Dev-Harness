# ============================================================
# selftest.ps1 - harness 冒烟自测（增强版）
# 覆盖：计划生成 / 执行 / 修改计划 / router 四模式 /
#       _detect ENGINE 显式 / SCOPE=off 预览
# ============================================================
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$HarnessRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)   # scripts → harness
$tempRoot = Join-Path $env:TEMP ('harness-selftest-' + [guid]::NewGuid().ToString('N'))
$oldPath = $env:PATH
$oldAutoGit = $env:AUTO_GIT_INIT
$oldEngine = $env:ENGINE
$oldScope = $env:SCOPE
$oldGate = $env:GATE_LEVEL

try {
  New-Item -ItemType Directory -Path (Join-Path $tempRoot 'bin') -Force | Out-Null
  Copy-Item -Recurse -LiteralPath $HarnessRoot -Destination (Join-Path $tempRoot 'harness')

  # 假 codex stub
  $stub = @'
@echo off
if "%~1"=="exec" echo ALL_DONE
exit /b 0
'@
  Set-Content -LiteralPath (Join-Path $tempRoot 'bin\codex.cmd') -Value $stub -Encoding ASCII

  $env:PATH = (Join-Path $tempRoot 'bin') + ';' + $env:PATH
  $env:AUTO_GIT_INIT = '0'
  $env:ENGINE = 'codex-cli'
  $env:GATE_LEVEL = '0'
  Remove-Item Env:SCOPE -ErrorAction SilentlyContinue
  $run = Join-Path $tempRoot 'harness\core\run.ps1'

  # 1) 生成计划路径（stub 引擎不写文件，仅验证流程退出码）
  Write-Host '--- 用例1：生成计划 ---'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $run '测试目标' | Out-Host
  if ($LASTEXITCODE -ne 0) { throw '生成计划路径失败' }

  # 2) 执行路径（stub 输出 ALL_DONE，GATE_LEVEL=0）
  Write-Host '--- 用例2：执行计划 ---'
  $null = New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot 'docs')
  Set-Content -LiteralPath (Join-Path $tempRoot 'docs\plan.md') -Value "# 测试计划`n- [ ] 任务1" -Encoding UTF8
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $run '测试目标' | Out-Host
  if ($LASTEXITCODE -ne 0) { throw '执行路径失败' }

  # 3) 修改计划路径
  Write-Host '--- 用例3：修改计划 ---'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $run '修改计划：增加测试模块' | Out-Host
  if ($LASTEXITCODE -ne 0) { throw '修改计划路径失败' }

  # 4) router.py 四模式
  Write-Host '--- 用例4：router 四模式 ---'
  $r1 = (& python (Join-Path $tempRoot 'harness\core\router.py') '修改计划：加模块' | Out-String)
  if ($r1 -notmatch '"PLAN"') { throw "router PLAN 模式失败: $r1" }
  $r2 = (& python (Join-Path $tempRoot 'harness\core\router.py') '写架构回顾' | Out-String)
  if ($r2 -notmatch '"PLAN_DOC"') { throw "router PLAN_DOC 模式失败: $r2" }
  $r3 = (& python (Join-Path $tempRoot 'harness\core\router.py') '修复登录bug' | Out-String)
  if ($r3 -notmatch '"TEST"') { throw "router TEST 模式失败: $r3" }
  $r4 = (& python (Join-Path $tempRoot 'harness\core\router.py') '实现登录功能' | Out-String)
  if ($r4 -notmatch '"EXEC"') { throw "router EXEC 模式失败: $r4" }
  Write-Host '✅ router 四模式正确'

  # 5) _detect ENGINE 显式
  Write-Host '--- 用例5：_detect 显式指定 ---'
  . (Join-Path $tempRoot 'harness\adapters\_detect.ps1')
  $env:ENGINE = 'deepseek-harness'
  if ((Get-Engine) -ne 'deepseek-harness') { throw '_detect deepseek-harness 失败' }
  $env:ENGINE = 'codex-cloud'
  if ((Get-Engine) -ne 'codex-cloud') { throw '_detect codex-cloud 失败' }
  $env:ENGINE = 'claude-code'
  if ((Get-Engine) -ne 'claude-code') { throw '_detect claude-code 失败' }
  Write-Host '✅ _detect 显式指定正确（含 claude-code）'

  # 6) 版本自检：零影响（不存在的引擎应静默；异常不应抛错）
  Write-Host '--- 用例6：版本自检零影响 ---'
  . (Join-Path $tempRoot 'harness\core\version-check.ps1')
  Test-EngineVersion -Engine 'codex-cli'   # 版本拿不到或匹配都应静默/仅提示
  Test-EngineVersion -Engine 'unknown-xyz' # 未知引擎应直接返回
  Write-Host '✅ 版本自检调用无异常（零影响）'

  # 7) SCOPE=off 只读预览
  Write-Host '--- 用例7：SCOPE=off 预览 ---'
  $env:SCOPE = 'off'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $run '测试目标' | Out-Host
  if ($LASTEXITCODE -ne 0) { throw 'SCOPE=off 路径失败' }
  Remove-Item Env:SCOPE -ErrorAction SilentlyContinue
  Remove-Item Env:ENGINE -ErrorAction SilentlyContinue

  Write-Host ''
  Write-Host '✅✅ selftest 全部通过'
} finally {
  $env:PATH = $oldPath
  $env:AUTO_GIT_INIT = $oldAutoGit
  $env:ENGINE = $oldEngine
  $env:SCOPE = $oldScope
  $env:GATE_LEVEL = $oldGate
  if (Test-Path -LiteralPath $tempRoot) {
    $resolved = (Resolve-Path -LiteralPath $tempRoot).Path
    $tempFull = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    if ($resolved.StartsWith($tempFull, [System.StringComparison]::OrdinalIgnoreCase)) {
      Remove-Item -LiteralPath $resolved -Recurse -Force
    }
  }
}
