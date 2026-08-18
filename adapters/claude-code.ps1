# ============================================================
# claude-code.ps1 - 适配器：Claude Code（Anthropic CLI）（N2）
# 版本适配：Claude Code 2.1.234 实测支持 -p/--print 非交互模式。
# 详细适配方案见 claude-code.md
# ============================================================

function Test-ClaudeCode {
  return [bool](Get-Command claude -ErrorAction SilentlyContinue)
}

function Get-AdapterInfo {
  return @{
    Name        = 'claude-code'
    Description = 'Claude Code（Anthropic CLI）：claude -p 非交互模式'
    Exec        = 'claude -p "指令" --output-format text --dangerously-skip-permissions'
    Rules       = 'CLAUDE.md（Claude Code 的规则文件，与 AGENTS.md 等价）'
    Model       = '由 Claude Code 配置/账号决定（可 --model 指定）'
    Mcp         = 'claude mcp add / 配置（支持 MCP）'
  }
}
