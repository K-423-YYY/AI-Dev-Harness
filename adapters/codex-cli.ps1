# ============================================================
# codex-cli.ps1 - 适配器：Codex CLI（本地客户端）（N2）
# 详细适配方案见 codex-cli.md
# ============================================================

function Test-CodexCli {
  return [bool](Get-Command codex -ErrorAction SilentlyContinue)
}

function Get-CodexCliModel {
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $config = Join-Path $codexHome 'config.toml'
  if (Test-Path -LiteralPath $config) {
    $line = Get-Content -LiteralPath $config | Where-Object { $_ -match '^\s*model\s*=' } | Select-Object -First 1
    if ($line -match '^\s*model\s*=\s*"([^"]+)"') { return $Matches[1] }
  }
  return '默认'
}

function Get-AdapterInfo {
  return @{
    Name        = 'codex-cli'
    Description = 'Codex CLI（本地客户端）：codex exec + workspace-write 沙箱'
    Exec        = 'codex exec "指令" --sandbox workspace-write --skip-git-repo-check'
    Rules       = 'AGENTS.md（自动加载）'
    Model       = Get-CodexCliModel
    Mcp         = 'codex mcp add memory/playwright/…'
  }
}
