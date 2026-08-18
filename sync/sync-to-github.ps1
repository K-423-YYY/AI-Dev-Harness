[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

# 用 Continue 而非 Stop：git 的 CRLF 警告等会写 stderr，
# 在 PowerShell 5.1 的 Stop 模式下会被包装成错误终止脚本。
# 成败一律以 $LASTEXITCODE 判断。
$ErrorActionPreference = 'Continue'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $ProjectRoot

$env:http_proxy = ""
$env:https_proxy = ""
$env:all_proxy = ""
$env:HTTP_PROXY = ""
$env:HTTPS_PROXY = ""
$env:ALL_PROXY = ""

git add -A 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "git add 失败" }

git commit -m $Message 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "git commit 失败（若没有改动则无需同步）" }

git push origin main 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "git push 失败，请检查网络或手动推送" }

Write-Host "✅ 已同步到 GitHub：$Message"
