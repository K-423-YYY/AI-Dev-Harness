# ============================================================
# codex-cloud.ps1 - 适配器：Codex Cloud（云端）（N2）
# 详细适配方案见 codex-cloud.md
# ============================================================

function Test-CodexCloud {
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { return $false }
  try {
    $status = (& codex login status 2>$null | Out-String)
    if ($status -match '(?i)cloud|remote|logged in') { return $true }
  } catch { }
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $config = Join-Path $codexHome 'config.toml'
  if (Test-Path -LiteralPath $config) {
    try {
      $raw = Get-Content -LiteralPath $config -Raw -ErrorAction SilentlyContinue
      if ($raw -match '(?im)remote\s*=\s*true' -or $raw -match '(?im)model_provider\s*=\s*"?(cloud|remote)') { return $true }
    } catch { }
  }
  return $false
}

function Get-AdapterInfo {
  return @{
    Name        = 'codex-cloud'
    Description = 'Codex Cloud（云端）：codex exec --remote，云端模型'
    Exec        = 'codex exec --remote "指令" --skip-git-repo-check'
    Rules       = 'AGENTS.md（随项目上传，同样生效）'
    Model       = '云端模型（无需本地 config.toml 模型配置）'
    Mcp         = '云端支持的 MCP 或本地转发'
  }
}
