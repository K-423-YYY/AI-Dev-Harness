# ============================================================
# codex-cloud.ps1 - 适配器：Codex Cloud（云端）（N2）
# 版本适配：codex-cli 0.147.0 无 "exec --remote"。
# Cloud 模式 = codex login（ChatGPT 账号）登录后，config.toml 中
# model_provider 指向云端（chatgpt/openai），exec 自动使用云端模型。
# 详细适配方案见 codex-cloud.md
# ============================================================

function Test-CodexCloud {
  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { return $false }
  # 方式 1：config.toml 中 model_provider 指向云端
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $config = Join-Path $codexHome 'config.toml'
  if (Test-Path -LiteralPath $config) {
    try {
      $raw = Get-Content -LiteralPath $config -Raw -ErrorAction SilentlyContinue
      if ($raw -match '(?im)^\s*model_provider\s*=\s*"(chatgpt|cloud|openai)"') { return $true }
      if ($raw -match '(?im)remote\s*=\s*true') { return $true }
    } catch { }
  }
  # 方式 2：登录态为 ChatGPT 账号（而非 API key）
  try {
    $status = (& codex login status 2>$null | Out-String)
    if ($status -match '(?i)chatgpt|logged in as|signed in.*chatgpt') { return $true }
  } catch { }
  return $false
}

function Get-AdapterInfo {
  return @{
    Name        = 'codex-cloud'
    Description = 'Codex Cloud（云端）：codex login(ChatGPT 账号) + config model_provider=chatgpt，exec 自动走云端模型'
    Exec        = 'codex exec "指令" --sandbox workspace-write --skip-git-repo-check（与 codex-cli 同；云端由登录态/配置决定）'
    Rules       = 'AGENTS.md（随项目上传，同样生效）'
    Model       = '云端模型（ChatGPT 账号登录后由 Codex 决定，如 o3/gpt-5-codex）'
    Mcp         = '云端支持的 MCP 或本地转发'
  }
}
