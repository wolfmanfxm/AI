# Discovery — Pipeline Orchestrator

> @engine: discovery

## Actions

1. `@adapter:filesystem.read runtime/registry/workflow-library.yaml` → 列出所有可用 pipeline
2. 读 `runtime/registry/capabilities.yaml` → 验证 pipeline 中每个 Skill 的 availability
3. 读 `.project-runtime/state.json`（若存在）→ 了解项目当前状态
4. 展示 pipeline 选项给用户：

```
可用的 Pipeline:

1. full-sdlc          — 全生命周期（8 skills, ~30min）
2. analyze-plan-build — 新功能开发（5 skills, ~15min）
3. quick-change       — 轻量改动（2 skills, ~5min）
4. refactor-cycle     — 重构循环（4 skills, ~10min）
5. knowledge-refresh  — 知识刷新（2 skills, ~5min）
```

5. CHECKPOINT — 用户选择 pipeline + 确认目标

## Exit

- 用户已选择 pipeline
- Pipeline 中所有 Skill 已验证可用
- 项目状态已了解

## Failure

| Condition | Action |
|-----------|--------|
| registry 文件不可读 | 🔴 BLOCKED |
| pipeline 中 Skill 不存在 | 标注缺失 Skill → AskUserQuestion：跳过/终止 |

## CHECKPOINT

🔴 CHECKPOINT — 展示 pipeline 选项，用户确认
