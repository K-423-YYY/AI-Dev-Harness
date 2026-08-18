# ============================================================
# install-global.ps1 - SCOPE=global 全局安装器（v3.0/v5.0）
# 1) 列出将写入的路径并要求确认
# 2) 复制技能到全局技能目录
# 3) 注册全局 harness 命令
# 4) （可选）注册 MCP 到全局 Codex 配置
# ============================================================
[CmdletBinding()]
param([string]$HarnessRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))

$ErrorActionPreference = 'Stop'
$userHome = $env:USERPROFILE
$globalSkills = Join-Path $userHome '.codex\skills'
$globalBin = Join-Path $userHome '.codex\bin'

Write-Host '🌐 全局安装将执行以下写入（均可通过 SCOPE=off 还原/关闭）：'
Write-Host "  1) 复制技能到：$globalSkills"
Write-Host "  2) 注册全局命令：$globalBin\harness.ps1"
Write-Host "  3) （可选）注册 MCP 到全局 Codex 配置"
$confirm = Read-Host '确认执行全局安装？输入 YES 继续'
if ($confirm -ne 'YES') { Write-Host '已取消。'; exit 0 }

# 1) 技能
$null = New-Item -ItemType Directory -Force -Path $globalSkills
foreach ($s in @('frontend-design', 'webapp-testing', 'backend-api', 'spec')) {
  $src = Join-Path $HarnessRoot "skills\$s"
  if (Test-Path -LiteralPath $src) {
    Copy-Item -Recurse -Force $src (Join-Path $globalSkills $s)
    Write-Host "✅ 已复制 skills/$s"
  }
}

# 2) 全局命令
$null = New-Item -ItemType Directory -Force -Path $globalBin
$runner = @"
# harness 全局命令入口
`$HarnessRoot = '$HarnessRoot'
`$Args2 = `$args -join ' '
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "`$HarnessRoot\core\run.ps1" `$Args2
exit `$LASTEXITCODE
"@
Set-Content -LiteralPath (Join-Path $globalBin 'harness.ps1') -Value $runner -Encoding UTF8
Write-Host "✅ 已注册全局命令：$globalBin\harness.ps1"
Write-Host "   使用：powershell -File $globalBin\harness.ps1 \"目标\""

# 3) MCP（可选，询问）
$mc = Read-Host '是否注册 memory/playwright MCP 到全局 Codex？(y/n)'
if ($mc -eq 'y' -and (Get-Command codex -ErrorAction SilentlyContinue)) {
  try {
    $list = (& codex mcp list 2>$null | Out-String)
    if ($list -notmatch 'memory') { & codex mcp add memory -- npx @modelcontextprotocol/server-memory 2>$null }
    if ($list -notmatch 'playwright') { & codex mcp add playwright -- npx @playwright/mcp@latest 2>$null }
    Write-Host '✅ MCP 注册完成'
  } catch { Write-Warning "MCP 注册失败：$($_.Exception.Message)" }
}

Write-Host '🎉 全局安装完成。任意目录可执行：harness "目标"'
Write-Host '   关闭影响：SCOPE=off　|　卸载：删除上面列出的全局目录。'
