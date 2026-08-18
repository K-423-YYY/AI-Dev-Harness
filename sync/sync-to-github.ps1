[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $ProjectRoot

$env:http_proxy = ""
$env:https_proxy = ""
$env:all_proxy = ""
$env:HTTP_PROXY = ""
$env:HTTPS_PROXY = ""
$env:ALL_PROXY = ""

git add -A
if ($LASTEXITCODE -ne 0) { throw "git add 失败" }

git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw "git commit 失败" }

git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push 失败，请检查网络或手动推送" }

Write-Host "✅ 已同步到 GitHub：$Message"
