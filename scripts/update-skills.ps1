[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$WorkflowDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$RepoUrl = 'https://github.com/anthropics/skills'
$tempRoot = Join-Path $env:TEMP ('codex-workflow-skills-' + [guid]::NewGuid().ToString('N'))

try {
  Write-Host '🔎 检测 GitHub 连通性...'
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host '⚠️ 未找到 git，保留本地技能版本。'
    exit 0
  }
  & git ls-remote --heads $RepoUrl HEAD 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host '⚠️ GitHub 不可达，保留本地技能版本。可稍后重试或配置代理。'
    exit 0
  }
  & git clone --depth 1 $RepoUrl (Join-Path $tempRoot 'skills') 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host '⚠️ 技能仓库克隆失败，保留本地技能版本。可稍后重试或配置代理。'
    exit 0
  }
  foreach ($skill in @('frontend-design', 'backend-api', 'webapp-testing')) {
    $src = Join-Path $tempRoot "skills\$skill"
    if (Test-Path -LiteralPath $src) {
      Copy-Item -LiteralPath $src -Destination (Join-Path $WorkflowDir "skills\$skill") -Recurse -Force
      Write-Host "✅ 已更新 skills/$skill"
    } else {
      Write-Host "ℹ️ 官方仓库无 $skill，保留本地版本"
    }
  }
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
