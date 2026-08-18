# ============================================================
# status.ps1 - 状态报告生成（N1-2：停止时反馈当前情况及可行方案）
# ============================================================

function Write-StatusReport {
  param(
    [int]$Round,
    [int]$MaxRounds,
    [int]$DoneCount,
    [int]$TotalCount,
    [string]$Reason,          # 停止原因
    [string]$Detail,          # 当前情况
    [string]$ProjectDocsDir   # 项目 docs/ 目录
  )
  $null = New-Item -ItemType Directory -Force -Path $ProjectDocsDir
  $file = Join-Path $ProjectDocsDir 'STATUS.md'
  $suggestions = @(
    '① 人工介入处理「需要手动操作的具体步骤」，完成后重跑同一命令续接',
    '② 调整/拆分计划书后重跑（"修改计划：…"）',
    ('③ 增大 MAX_ROUNDS（当前 ' + $MaxRounds + '）或调大 ROUND_TIMEOUT'),
    '④ 检查验证脚本（verify/spec-check/e2e）或降级 GATE_LEVEL',
    '⑤ 查看 docs/CHECKPOINTS.md 与 git log 定位回滚点'
  )
  $content = @"
# 状态报告（STATUS.md）

- 停止轮次：第 $Round / $MaxRounds 轮
- 已完成任务：$DoneCount / $TotalCount
- 未完成任务：$($TotalCount - $DoneCount)
- 停止原因：$Reason
- 当前情况：$Detail

## 可行方案
$($suggestions -join "`n")
"@
  Set-Content -LiteralPath $file -Value $content -Encoding UTF8
  Write-Host ""
  Write-Host "⚠️  已停止（第 $Round/$MaxRounds 轮），状态报告已写入：$file"
  Write-Host "   停止原因：$Reason"
  Write-Host "   已完成：$DoneCount / $TotalCount"
  Write-Host "   当前情况：$Detail"
  Write-Host ""
  Write-Host "   ${suggestions}"
  Write-Host ""
  return $file
}
