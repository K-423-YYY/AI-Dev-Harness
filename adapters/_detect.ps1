# ============================================================
# _detect.ps1 - 软件自动识别（N2）
# 优先级：ENGINE 环境变量 > 自动检测 > unsupported（未适配不执行）
# 检测顺序：Codex（Cloud/CLI）→ Claude Code → DeepSeek Harness
# 提供函数: Get-Engine
# ============================================================

function Get-Engine {
  # 1) 显式指定
  if ($env:ENGINE) {
    $e = $env:ENGINE.ToLower()
    if ($e -in @('codex-cli', 'codex-cloud', 'claude-code', 'deepseek-harness')) { return $e }
    Write-Host "⚠️ 未知 ENGINE=$env:ENGINE，回退自动检测"
  }

  # 2) Codex 检测（Cloud / CLI）
  if (Get-Command codex -ErrorAction SilentlyContinue) {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
    $config = Join-Path $codexHome 'config.toml'
    $isCloud = $false
    if (Test-Path -LiteralPath $config) {
      try {
        $raw = Get-Content -LiteralPath $config -Raw -ErrorAction SilentlyContinue
        if ($raw -match '(?im)^\s*model_provider\s*=\s*"(chatgpt|cloud|openai)"') { $isCloud = $true }
        elseif ($raw -match '(?im)remote\s*=\s*true') { $isCloud = $true }
      } catch { }
    }
    if (-not $isCloud) {
      # 登录态兜底：ChatGPT 账号登录视为 Cloud
      try {
        $status = (& codex login status 2>$null | Out-String)
        if ($status -match '(?i)chatgpt|logged in as') { $isCloud = $true }
      } catch { }
    }
    return $(if ($isCloud) { 'codex-cloud' } else { 'codex-cli' })
  }

  # 3) Claude Code 检测
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    return 'claude-code'
  }

  # 4) DeepSeek Harness 检测
  $dshEnv = $false
  foreach ($k in $env.GetEnumerator()) {
    if ($k.Name -like 'DSH*') { $dshEnv = $true; break }
  }
  if ($dshEnv -or (Get-Command dsh -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.dsh'))) {
    return 'deepseek-harness'
  }

  # 5) 未适配
  return 'unsupported'
}
