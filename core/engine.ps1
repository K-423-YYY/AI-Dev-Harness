# ============================================================
# engine.ps1 - AI-Dev-Harness 引擎核心函数库（执行 / 超时 / 异常检测）
# 由 run.ps1 加载调用
# 版本适配说明：
#   - codex-cli 0.147.0：codex exec 支持 --sandbox / --skip-git-repo-check，无 --remote
#   - codex-cloud（当前版本无 exec --remote）：Cloud 由登录态/配置决定，exec 同 codex-cli
#   - deepseek-harness：优先 dsh --profile headless 真实执行，失败回落桥接模式
# ============================================================

$script:Engine = 'unsupported'

function Set-Engine {
  param([string]$Name)
  $script:Engine = $Name
}

function Get-EngineName { return $script:Engine }

# 构造引擎执行命令行（返回字符串数组）
function Get-ExecCommandLine {
  param([string]$Prompt)
  switch ($script:Engine) {
    'codex-cli'   { return @('codex', 'exec', $Prompt, '--sandbox', 'workspace-write', '--skip-git-repo-check') }
    # Codex Cloud：当前 codex 版本（0.147.0）无 exec --remote；云端由登录态/配置(model_provider)决定
    'codex-cloud' { return @('codex', 'exec', $Prompt, '--sandbox', 'workspace-write', '--skip-git-repo-check') }
    default       { return $null }
  }
}

# 执行一次引擎调用；支持超时终止；返回输出文本
function Invoke-EngineExec {
  param(
    [string]$Prompt,
    [string]$LogBase,
    [int]$TimeoutSec = 600
  )
  if ($script:Engine -eq 'deepseek-harness') {
    # DSH 真实执行：优先 headless 模式（dsh --profile headless "任务"）
    if (Get-Command dsh -ErrorAction SilentlyContinue) {
      $dsOut = & dsh --profile headless $Prompt 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0 -and $dsOut -notmatch '^\s*$') { return $dsOut }
    }
    # 回落桥接模式：把执行指令写入 docs/exec-prompt.md，交由 DSH 中的 AI 执行
    $promptFile = Join-Path (Get-Location) 'docs\exec-prompt.md'
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $promptFile)
    $content = "# DSH 桥接执行指令`n`n请按以下指令执行，完成后更新 plan.md 勾选状态并运行验证脚本：`n`n$Prompt`n"
    Set-Content -LiteralPath $promptFile -Value $content -Encoding UTF8
    Write-Host "📄 已将本轮执行指令写入 docs/exec-prompt.md（DeepSeek Harness 桥接模式）"
    Write-Host "   请将该文件内容交给 DSH 中的 AI 执行，执行后重跑本脚本继续。"
    return '[DSH_BRIDGE]'
  }
  $cmd = Get-ExecCommandLine -Prompt $Prompt
  if (-not $cmd) { return '[UNSUPPORTED]' }

  $outLog = "$LogBase.out.log"
  $errLog = "$LogBase.err.log"
  # 手动为含空格的参数加引号，避免 Start-Process 丢参
  $argStr = (($cmd[1..($cmd.Length - 1)] | ForEach-Object {
    if ($_ -match '\s') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' ')

  $proc = Start-Process -FilePath $cmd[0] -ArgumentList $argStr -NoNewWindow `
    -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
  if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
    try { $proc.Kill() } catch { }
    return "[TIMEOUT] 单轮执行超过 $TimeoutSec 秒，已终止。可调大 ROUND_TIMEOUT。"
  }
  $out = if (Test-Path $outLog) { Get-Content -LiteralPath $outLog -Raw -ErrorAction SilentlyContinue } else { '' }
  $err = if (Test-Path $errLog) { Get-Content -LiteralPath $errLog -Raw -ErrorAction SilentlyContinue } else { '' }
  return "$out`n$err"
}

# 统计 plan.md 中已完成勾选的任务数（用于无进展检测）
function Get-PlanDoneCount {
  param([string]$PlanFile)
  if (-not (Test-Path -LiteralPath $PlanFile)) { return 0 }
  $c = Get-Content -LiteralPath $PlanFile -Raw -ErrorAction SilentlyContinue
  return ([regex]::Matches($c, '\[x\]')).Count
}

# Git 进度保存（每轮检查点）
function Save-GitProgress {
  param([string]$Message, [string]$ProjectRoot)
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }
  Push-Location $ProjectRoot
  try {
    & git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      if ($env:AUTO_GIT_INIT -ne '0') {
        $gi = Join-Path $ProjectRoot '.gitignore'
        if (-not (Test-Path -LiteralPath $gi)) {
          @'
node_modules/
dist/
coverage/
.git/
.env
venv/
__pycache__/
'@ | Set-Content -LiteralPath $gi -Encoding UTF8
        }
        & git init 2>$null | Out-Null
      } else { return }
    }
    & git add -A 2>$null | Out-Null
    & git commit -m "AI-Dev-Harness: $Message" 2>$null | Out-Null
  } catch { }
  finally { Pop-Location }
}
