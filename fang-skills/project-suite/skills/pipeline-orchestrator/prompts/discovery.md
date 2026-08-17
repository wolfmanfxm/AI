# Discovery — Pipeline Orchestrator

> @engine: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：查询项目当前 knowledge

0.5. 🔒 **强制执行 Complexity Gate（不可绕过）** → [Complexity Gate](../../../shared/prompts/complexity-gate.md)：
    - **先查复用**：需求已被现有组件/模式覆盖 → Reuse Fast Path 零改动，**直接结束，不 dispatch 任何 Skill**。
    - **再定复杂度**：调 `bash shared/scripts/complexity-gate.sh "<需求>"` → simple/medium/complex。
    - **Gate 是唯一路由入口**：orchestrator 禁止绕过 Gate 直接 dispatch Skill；每个 pipeline 都必须由 Gate 选定。

1. `@adapter:filesystem.read runtime/registry/workflow-library.yaml` → 列出所有可用 pipeline
2. 读 `runtime/registry/capabilities.yaml` → 验证 pipeline 中每个 Skill 的 availability
3. 读 `.project-runtime/state.json`（若存在）→ 了解项目当前状态
4. 展示 pipeline 选项给用户（**Gate 选定的路径置顶**，其余折叠为「其他」）：

```
Gate 判定: [Reuse Fast Path | Quick | Standard | Full]（复杂度: X）
可用的 Pipeline:
1. ★ quick-change       — Gate 选定（Quick Path）
2. analyze-plan-build   — Standard Path
3. full-sdlc            — Full Path
...
```

5. CHECKPOINT — 用户确认 Gate 选定的路径（或显式覆盖，需说明理由）

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
