[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Get-Location).Path

function Invoke-ProjectChecks {
  param([string]$Dir)

  if (-not (Test-Path -LiteralPath (Join-Path $Dir 'package.json'))) { return }
  Write-Host "🔎 验证 $Dir ..."
  Push-Location -LiteralPath $Dir
  try {
    $pkgManager = 'pnpm'
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
      if (Get-Command npm -ErrorAction SilentlyContinue) {
        $pkgManager = 'npm'
      } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
        $pkgManager = 'yarn'
      } else {
        Write-Warning "未找到 pnpm/npm/yarn，跳过 $Dir 验证"
        return
      }
    }

    & $pkgManager install --silent
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $pkgManager lint
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $pkgManager test
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $pkgManager build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $pkgManager typecheck
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  } finally {
    Pop-Location
  }
}

Invoke-ProjectChecks 'frontend'
Invoke-ProjectChecks 'backend'

Write-Host '✅ 验证通过'
exit 0
