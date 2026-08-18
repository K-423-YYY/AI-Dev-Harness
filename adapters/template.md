# 适配器扩展模板

> 用于新增对其他 AI 软件/客户端的适配。复制本模板为 `adapters/<name>.ps1` 与 `adapters/<name>.md`，填写以下统一接口，并在 `_detect.ps1` / `_detect.sh` 的检测链中追加识别分支。

## 统一接口契约（core 引擎通过以下接口调用适配器，不感知具体软件）

| 接口 | 说明 | 实现位置 |
|---|---|---|
| `run_exec(prompt)` | 执行一次 AI 调用，返回输出文本 | engine.ps1 的 Invoke-EngineExec 分支 |
| `model_info()` | 返回当前模型信息 | 适配器 .ps1 的 Get-AdapterInfo |
| `load_rules()` | 规则文件加载方式（AGENTS.md 等） | 适配器 .md 文档说明 |
| `install_mcp()` | MCP 安装命令 | 适配器 .md 文档说明 |
| `sandbox_flags` | 非交互/沙箱参数 | 适配器 .md 文档说明 |

## <名称>.ps1 骨架

```powershell
function Test-<Name> { return $false }            # 检测函数
function Get-AdapterInfo {
  return @{
    Name = '<name>'
    Description = '...'
    Exec = '...'
    Rules = '...'
    Model = '...'
    Mcp = '...'
  }
}
```

## <名称>.md 骨架（按 N2-1 要求单独写出适配方案）

```markdown
# 适配方案：<名称>
| 项 | 适配内容 |
|---|---|
| 检测 | ... |
| 执行命令 | ... |
| 规则加载 | ... |
| 模型 | ... |
| MCP | ... |
| 特点 | ... |
## 使用前提
## 参数适配注意
```

## 接入步骤
1. 复制模板 → 填写检测函数（Test-<Name>）。
2. 在 engine.ps1 的 Get-ExecCommandLine 增加执行分支。
3. 在 _detect.ps1 / _detect.sh 检测链追加识别分支。
4. 更新未适配提示中的支持列表。
5. 在 selftest 增加该引擎用例。
