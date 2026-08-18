#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""任务路由：PLAN / PLAN_DOC / TEST / EXEC 四模式 + RUN_AS 角色（A 的 subagent_router.py 落地版）。"""
import sys, json

def route_task(user_prompt):
    prompt = user_prompt.lower()
    # 修改计划（B 保留，优先级最高）
    if any(k in prompt for k in ["修改计划", "编辑计划", "更新计划", "update plan", "edit plan"]):
        return {"mode": "PLAN", "role": "planner",
                "context_files": ["docs/plan.md"],
                "instruction": "直接编辑 docs/plan.md，不要编写其他代码。"}
    # 架构 / 设计 / 回顾（A planner 分支）
    if any(k in prompt for k in ["plan", "design", "方案", "设计", "架构", "回顾", "review", "architecture"]):
        return {"mode": "PLAN_DOC", "role": "planner",
                "context_files": ["docs/ARCHITECTURE.md"],
                "instruction": "使用 SDD 规范输出极简设计方案。"}
    # 测试 / 修复 / 验收（A tester 分支）
    if any(k in prompt for k in ["test", "bug", "403", "fix", "测试", "报错", "验收", "e2e"]):
        return {"mode": "TEST", "role": "tester",
                "context_files": ["docs/CHECKPOINTS.md"],
                "instruction": "分析日志，启动单点修复流程。"}
    # 默认执行（A coder 分支）
    return {"mode": "EXEC", "role": "coder",
            "context_files": ["docs/ARCHITECTURE.md"],
            "instruction": "读取 Spec 规范，执行模块局部编码。"}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        task = " ".join(sys.argv[1:])
        config = route_task(task)
        print("[Harness Router] 分发配置:")
        print(json.dumps(config, ensure_ascii=False, indent=2))
    else:
        print("用法: python3 core/router.py <需求描述>")
