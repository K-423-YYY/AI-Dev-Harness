@echo off
rem ============================================================
rem  Codex Harness 一键全栈开发引擎 - Windows 入口
rem  用法: run.bat "你的项目目标"   或双击打开交互菜单
rem ============================================================
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
exit /b %ERRORLEVEL%
