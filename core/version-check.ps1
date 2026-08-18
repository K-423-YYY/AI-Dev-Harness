# ============================================================
# version-check.ps1 - 版本自检（零影响设计）
# 设计原则：
#   1. 只读：仅查询引擎版本并打印提示，不修改任何文件/配置。
#   2. 静默：任何失败（命令不存在/超时/解析错误）都静默返回。
#   3. 不影响执行：绝不改变流程、退出码或引擎行为；仅在不匹配时输出 ℹ️ 提示。
# 由 run.ps1 在识别引擎后调用。
# ============================================================

# 内置"已知兼容版本"清单（实测于 2026-08）。引擎升级后在此更新即可。
$script:KnownEngineVersions = @{
  'codex-cli'        = '0.147.0'
  'codex-cloud'      = '0.147.0'
  'claude-code'      = '2.1.234'
  'deepseek-harness' = '0.1.0-rc.6'
}

function Test-EngineVersion {
  param([string]$Engine)
  # 未适配 / 未知引擎不检查
  if (-not $script:KnownEngineVersions.ContainsKey($Engine)) { return }
  try {
    $actual = $null
    switch ($Engine) {
      'codex-cli'   { $actual = (& codex --version 2>$null | Select-Object -First 1) }
      'codex-cloud' { $actual = (& codex --version 2>$null | Select-Object -First 1) }
      'claude-code' { $actual = (& claude --version 2>$null | Select-Object -First 1) }
      'deepseek-harness' { $actual = (& dsh --version 2>$null | Select-Object -First 1) }
    }
    if (-not $actual) { return }  # 拿不到版本 → 静默
    $known = $script:KnownEngineVersions[$Engine]
    if (-not $known) { return }
    # 宽松匹配：实际版本包含已知版本号即视为兼容（容忍前缀/后缀）
    if ($actual -match [regex]::Escape($known)) { return }  # 匹配 → 静默通过
    # 不匹配 → 仅提示，不阻断
    Write-Host ""
    Write-Host "ℹ️ [版本自检] $Engine 当前版本: $($actual.Trim())（内置已知兼容: $known）"
    Write-Host "   若命令参数报错，请先运行对应工具 --help 核对，并更新 adapters/*.md 与 core/engine.ps1。"
    Write-Host "   （本提示不影响执行，可忽略）"
    Write-Host ""
  } catch { }
}
