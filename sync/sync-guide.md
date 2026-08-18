# GitHub 同步说明

本文件夹用于存放与 GitHub 同步相关的必要文件和说明。

## 远程仓库

```text
https://github.com/K-423-YYY/codex-workflow
```

## 同步命令

在项目根目录执行：

```powershell
git add -A
git commit -m "更新说明"
git push origin main
```

如果网络报错，先清代理：

```powershell
$env:http_proxy=""
$env:https_proxy=""
$env:all_proxy=""
git push origin main
```

## 一键同步

也可以直接运行：

```powershell
.\github-sync\sync-to-github.ps1 "更新说明"
```

## 注意事项

- 不要提交 `.env`、日志、临时文件。
- 推送前先运行 `git status` 检查文件。
- 如果自动化环境无法推送，请在本机终端手动执行上面的命令。
