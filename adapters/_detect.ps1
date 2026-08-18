# ============================================================
# _detect.ps1 - 软件自动识别（N2）
# 优先级：ENGINE 环境变量 > 自动检测 > unsupported（未适配不执行）
# 提供函数: Get-Engine
# ============================================================

function Get-Engine {
  # 1) 显式指定
  if ($env:ENGINE) {
    $e = $env:ENGINE.ToLower()
    if ($e -in @('codex-cli', 'codex-cloud', 'deepseek-harness')) { return $e }
    Write-Host "⚠️ 未知 ENGINE=$env:ENGINE，回退自动检测"
  }

  # 2) Codex 检测
  if (Get-Command codex -ErrorAction SilentlyContinue) {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
    $config = Join-Path $codexHome 'config.toml'
    $isCloud = $false
    if (Test-Path -LiteralPath $config) {
      try {
        $raw = Get-Content -LiteralPath $config -Raw -ErrorAction SilentlyContinue
        if ($raw -match '(?im)remote\s*=\s*true' -or $raw -match '(?im)cloud' -or $raw -match '(?im)model_provider\s*=\s*"?(cloud|remote)') {
          $isCloud = $true
        }
      } catch { }
    }
    return $(if ($isCloud) { 'codex-cloud' } else { 'codex-cli' })
  }

  # 3) DeepSeek Harness 检测
  $dshEnv = $false
  foreach ($k in $env.GetEnumerator()) {
    if ($k.Name -like 'DSH*') { $dshEnv = $true; break }
  }
  if ($dshEnv -or (Get-Command dsh -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.dsh'))) {
    return 'deepseek-harness'
  }

  # 4) 未适配
  return 'unsupported'
}
