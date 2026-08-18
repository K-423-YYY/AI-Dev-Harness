# ============================================================
# run.ps1 - Codex Harness 一键全栈开发引擎 主入口（v5.0）
# 用法:  .\harness\core\run.ps1 "你的项目目标"
#        双击 run.bat 打开交互菜单
# ============================================================
[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$InputArgs
)
$ErrorActionPreference = 'Stop'

# ---------- 路径定位 ----------
$WorkflowDir = Split-Path -Parent $MyInvocation.MyCommand.Path   # ...\harness\core
$HarnessRoot = Split-Path -Parent $WorkflowDir                   # ...\harness
$ProjectRoot = Split-Path -Parent $HarnessRoot                   # 项目根目录
Set-Location -LiteralPath $ProjectRoot

# ---------- 加载模块 ----------
. (Join-Path $WorkflowDir 'engine.ps1')
. (Join-Path $WorkflowDir 'status.ps1')
. (Join-Path $HarnessRoot 'adapters\_detect.ps1')

# ---------- 作用域解析（v3.0）----------
$scope = if ($env:SCOPE) { $env:SCOPE } else { 'local' }

# ---------- 软件自动识别（N2）----------
$engine = Get-Engine
Set-Engine $engine
Write-Host "🔍 识别引擎：$engine　|　作用域：$scope"

if ($engine -eq 'unsupported') {
  Write-Host ""
  Write-Host "❌ 当前环境未适配 Codex Harness 工作流。"
  Write-Host "   支持列表：Codex CLI / Codex Cloud / DeepSeek Harness"
  Write-Host "   请安装其一，或设置 ENGINE=codex-cli|codex-cloud|deepseek-harness 显式指定。"
  exit 1
}

# ---------- SCOPE=off：只读预览（N5）----------
if ($scope -eq 'off') {
  $previewMax = if ($env:MAX_ROUNDS) { $env:MAX_ROUNDS } else { 5 }
  Write-Host "🔕 SCOPE=off：零写入零修改（只读预览模式）。"
  Write-Host "   将执行的动作预览："
  Write-Host "    - 生成/更新计划书（docs/plan.md）"
  Write-Host "    - 循环执行计划（最多 $previewMax 轮，默认 5）"
  Write-Host "    - 验证（verify / spec-check / e2e）与 Git 提交"
  Write-Host "    - 记忆更新（ARCHITECTURE / CHECKPOINTS）"
  Write-Host "   当前不写入任何文件。"
  exit 0
}

# ---------- SCOPE=global：全局安装（N5）----------
if ($scope -eq 'global') {
  Write-Host "🌐 SCOPE=global：执行全局安装..."
  $installer = Join-Path $HarnessRoot 'scripts\install-global.ps1'
  if (Test-Path -LiteralPath $installer) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -HarnessRoot $HarnessRoot
    exit $LASTEXITCODE
  }
  Write-Warning "未找到 install-global.ps1"
  exit 1
}

# ---------- 环境检查 ----------
if ($engine -eq 'codex-cli' -or $engine -eq 'codex-cloud') {
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Error '未找到 codex 命令，请先安装并登录 Codex CLI（或使用 DeepSeek Harness 环境）。'
    exit 1
  }
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Warning '未找到 python（router.py 需要），路由将退化为内置关键词判断。'
}

# ---------- 输入解析 ----------
$inputText = ($InputArgs -join ' ').Trim()

# 交互菜单（无参数 / 双击场景）
if ([string]::IsNullOrWhiteSpace($inputText)) {
  Write-Host ""
  Write-Host "=== Codex Harness 一键开发引擎 ==="
  Write-Host "当前引擎: $engine　|　当前作用域: $scope（可用 SCOPE=global/off 切换）"
  Write-Host "1) 生成 / 查看计划书"
  Write-Host "2) 开始执行（按计划自动开发-验证-修复）"
  Write-Host "3) 修改计划书"
  Write-Host "4) 安装为全局命令（SCOPE=global）"
  Write-Host "5) 关闭影响 / 只读预览（SCOPE=off）"
  Write-Host "0) 退出"
  $choice = Read-Host "请选择"
  switch ($choice) {
    '1' { $inputText = '生成计划'; $genOnly = $true }
    '2' { $inputText = '执行计划'; }
    '3' { $inputText = '修改计划：' + (Read-Host '请输入修改要求'); }
    '4' { $env:SCOPE = 'global'; & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkflowDir 'run.ps1'); exit 0 }
    '5' { $env:SCOPE = 'off'; & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $WorkflowDir 'run.ps1'); exit 0 }
    default { exit 0 }
  }
}

# ---------- 路由解析（A 的 subagent_router 落地）----------
$mode = 'EXEC'; $role = 'coder'
$routerOut = $null
try {
  $routerOut = (& python (Join-Path $WorkflowDir 'router.py') $inputText 2>$null | Out-String)
  $route = $routerOut | ConvertFrom-Json
  $mode = $route.mode; $role = $route.role
} catch { }
if ($env:RUN_AS) { $role = $env:RUN_AS }

# ---------- 计划文件定位（SCOPE=local 写入项目根 docs/）----------
$planFile = Join-Path $ProjectRoot 'docs\plan.md'
$planRel = 'docs/plan.md'
$archFile = Join-Path $ProjectRoot 'docs\ARCHITECTURE.md'
$ckptFile = Join-Path $ProjectRoot 'docs\CHECKPOINTS.md'
$docsDir = Join-Path $ProjectRoot 'docs'
$null = New-Item -ItemType Directory -Force -Path $docsDir

# ---------- PLAN 模式：修改计划书 ----------
if ($mode -eq 'PLAN' -or $inputText -match '修改计划|编辑计划|更新计划') {
  Write-Host "📝 检测到计划书修改请求，直接更新 $planRel"
  $prompt = "请根据以下要求修改计划书：$inputText。按 SDD 格式（目标/需求补全/任务分解/验收标准/验证方式）编辑 $planRel，每项任务必须可单轮完成并有独立验收标准。不要编写其他代码。"
  $out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $docsDir '.harness-log\plan') -TimeoutSec 600
  Save-GitProgress -Message '更新计划书' -ProjectRoot $ProjectRoot
  exit 0
}

# ---------- PLAN_DOC / TEST 模式：单角色执行 ----------
if ($mode -eq 'PLAN_DOC' -or $mode -eq 'TEST') {
  Write-Host "🎯 角色任务（$role）：$inputText"
  $prompt = "本轮角色=$role。请按指令执行：$inputText。载入 $planRel 与 docs/ARCHITECTURE.md。完成后更新记忆文档。"
  $out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $docsDir '.harness-log\role') -TimeoutSec 900
  Save-GitProgress -Message "角色任务($role)" -ProjectRoot $ProjectRoot
  exit 0
}

# ---------- 生成计划分支 ----------
if (-not (Test-Path -LiteralPath $planFile)) {
  Write-Host '📋 未找到计划书，自动根据目标生成计划...'
  $prompt = "请调用 skills/spec/spec-writer.md 的方法，根据目标「$inputText」生成专业开发计划，保存到 $planRel。必须包含：目标、需求补全（目标用户/核心场景/范围外/技术选型）、任务分解表（#|任务|优先级|状态）、每项验收标准、验证方式。过大的任务必须拆分为子任务。请先补全需求中的模糊点，再输出计划。不要写代码。"
  $out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $docsDir '.harness-log\gen') -TimeoutSec 900
  Write-Host "✅ 计划已生成：$planFile"
  Write-Host '你可以查看或修改计划，然后再次运行本脚本开始执行。'
  Save-GitProgress -Message '生成计划书' -ProjectRoot $ProjectRoot
  exit 0
}

# ---------- PLAN_APPROVAL 审批门槛（A）----------
if ($env:PLAN_APPROVAL -eq '1') {
  Write-Host 'PLAN_APPROVAL 已开启：请人工确认 docs/plan.md，输入 APPROVED 继续。'
  $confirm = Read-Host '确认后输入 APPROVED'
  if ($confirm -ne 'APPROVED') { Write-Warning '未确认，退出。'; exit 1 }
}

# ---------- 执行循环（N1：最多 5 轮 + 异常处理）----------
$maxRounds = 5
if ($env:MAX_ROUNDS -match '^\d+$') { $maxRounds = [int]$env:MAX_ROUNDS }
$roundTimeout = 600
if ($env:ROUND_TIMEOUT -match '^\d+$') { $roundTimeout = [int]$env:ROUND_TIMEOUT * 60 }

Write-Host "🚀 开始自动执行计划：$planRel（最多 $maxRounds 轮）"

$logDir = Join-Path $docsDir '.harness-log'
$null = New-Item -ItemType Directory -Force -Path $logDir
$prevDone = -1
$noProgressRounds = 0
$stopReason = ''; $stopDetail = ''

for ($i = 1; $i -le $maxRounds; $i++) {
  Write-Host "🔄 第 $i 轮执行"

  # 角色指令（A 的 Agent 阵列落地）
  $roleInstr = switch ($role) {
    'planner' { '本轮角色=Planner：仅做设计决策与计划/架构文档更新，不写业务代码。' }
    'tester'  { '本轮角色=Tester：优先运行验证与测试、定位缺陷，修复由下一轮 Coder 完成。' }
    'coder'   { '本轮角色=Coder：仅按 plan.md 实现/修复代码，不扩大范围。' }
    default   { '按 plan.md 执行开发与修复。' }
  }

  $prompt = "请严格按照 $planRel 执行。$roleInstr 使用 memory MCP 记录进度；每完成一个子功能：更新 $planRel 勾选 → 增量追加 docs/ARCHITECTURE.md → 写入 docs/CHECKPOINTS.md；运行 scripts/verify.ps1 验证，失败则定位并修复。若所有任务已完成，报告完成。若遇到必须用户手动操作的地方，输出 NEED_HUMAN: <说明> 并停止。"
  $out = Invoke-EngineExec -Prompt $prompt -LogBase (Join-Path $logDir "round-$i") -TimeoutSec $roundTimeout

  # ---- 异常检测 1：NEED_HUMAN（需人工操作，N1-3）----
  if ($out -match 'NEED_HUMAN:?\s*(.+)') {
    $humanNeed = $Matches[1].Trim()
    Write-StatusReport -Round $i -MaxRounds $maxRounds `
      -DoneCount (Get-PlanDoneCount $planFile) -TotalCount 0 `
      -Reason '需人工操作（NEED_HUMAN）' -Detail $humanNeed -ProjectDocsDir $docsDir
    Save-GitProgress -Message "第 $i 轮需人工操作" -ProjectRoot $ProjectRoot
    Write-Host "   请按以上指引手动处理后，重跑同一命令续接。"
    exit 0
  }

  # ---- 异常检测 2：超时 / 卡住 ----
  if ($out -match '\[TIMEOUT\]') {
    $noProgressRounds++
    Write-Host "⚠️ 本轮超时（已连续 $noProgressRounds 轮无进展）"
    if ($noProgressRounds -ge 2) {
      Write-StatusReport -Round $i -MaxRounds $maxRounds `
        -DoneCount (Get-PlanDoneCount $planFile) -TotalCount 0 `
        -Reason '卡住（连续超时/无进展）' -Detail $out -ProjectDocsDir $docsDir
      exit 0
    }
    Save-GitProgress -Message "第 $i 轮超时" -ProjectRoot $ProjectRoot
    continue
  }

  # ---- 异常检测 3：无进展（连续 2 轮完成项无增长）----
  $done = Get-PlanDoneCount $planFile
  if ($done -le $prevDone) { $noProgressRounds++ } else { $noProgressRounds = 0 }
  $prevDone = $done
  Write-Host "   已完成勾选任务数：$done"
  if ($noProgressRounds -ge 2) {
    Write-StatusReport -Round $i -MaxRounds $maxRounds `
      -DoneCount $done -TotalCount 0 `
      -Reason '卡住（连续 2 轮无进展）' -Detail '任务勾选数未增长，可能陷入死循环或卡住。' -ProjectDocsDir $docsDir
    exit 0
  }

  Save-GitProgress -Message "第 $i 轮执行进度" -ProjectRoot $ProjectRoot

  # ---- 验证层（GATE_LEVEL 分层）----
  $verifyOk = $true
  if ($env:GATE_LEVEL -eq '2') {
    Write-Host '🔎 [e2e] 浏览器自测...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $HarnessRoot 'scripts\e2e.ps1')
    if ($LASTEXITCODE -ne 0) { $verifyOk = $false }
  }
  if ($env:GATE_LEVEL -ge '1' -and $verifyOk) {
    Write-Host '🔎 [spec-check] SDD 验收核对...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $HarnessRoot 'scripts\spec-check.ps1')
    if ($LASTEXITCODE -ne 0) { $verifyOk = $false }
  }
  if ($verifyOk) {
    Write-Host '🔎 [verify] 静态验证...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $HarnessRoot 'scripts\verify.ps1')
    if ($LASTEXITCODE -ne 0) { $verifyOk = $false }
  }

  if ($verifyOk) {
    Write-Host '✅ 验证通过，检查是否全部完成...'
    $checkPrompt = "请检查 $planRel 中的任务是否全部标记完成。若全部完成，只输出 ALL_DONE。"
    $checkOut = Invoke-EngineExec -Prompt $checkPrompt -LogBase (Join-Path $logDir "check-$i") -TimeoutSec 300
    if ($checkOut -match 'ALL_DONE') {
      Write-Host '🎉 项目完成！'
      Save-GitProgress -Message '项目完成' -ProjectRoot $ProjectRoot
      exit 0
    }
  } else {
    Write-Host '⚠️ 验证失败，继续下一轮修复'
  }
}

# ---------- 达到最大轮次（N1-1）----------
Write-StatusReport -Round $maxRounds -MaxRounds $maxRounds `
  -DoneCount (Get-PlanDoneCount $planFile) -TotalCount 0 `
  -Reason '达到最大执行轮次（5）' -Detail '多次执行/验证后仍未全部完成。' -ProjectDocsDir $docsDir
exit 1
