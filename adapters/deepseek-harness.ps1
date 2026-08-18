# ============================================================
# deepseek-harness.ps1 - 适配器：DeepSeek Harness（DSH）（N2）
# 详细适配方案见 deepseek-harness.md
# 桥接模式：harness 将执行指令写入 docs/exec-prompt.md，
# 交由 DSH 中的 AI（agent）读取并执行，执行后重跑脚本续接。
# ============================================================

function Test-DshEnv {
  foreach ($k in $env.GetEnumerator()) {
    if ($k.Name -like 'DSH*') { return $true }
  }
  if (Get-Command dsh -ErrorAction SilentlyContinue) { return $true }
  if (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.dsh')) { return $true }
  return $false
}

function Get-AdapterInfo {
  return @{
    Name        = 'deepseek-harness'
    Description = 'DeepSeek Harness（DSH）：桥接模式，指令经 docs/exec-prompt.md 交给 DSH 中的 AI 执行'
    Exec        = '桥接：写入 docs/exec-prompt.md（方式 A）；或注册为 DSH 动态插件（方式 B）'
    Rules       = '项目 AGENTS.md 作为会话指令注入'
    Model       = '由 DSH 配置决定（DeepSeek 等）'
    Mcp         = '与 DSH 沙箱/审批机制集成'
  }
}
