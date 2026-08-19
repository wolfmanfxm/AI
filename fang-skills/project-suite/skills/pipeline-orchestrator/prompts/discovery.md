# Discovery — Pipeline Orchestrator

> @template: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：查询项目当前 knowledge

0.5. 🔒 **必须走 Complexity Gate（不可绕过，由 Host 执行）** → [Complexity Gate](../../../shared/prompts/complexity-gate.md)：
    - **先查复用**：需求已被现有组件/模式覆盖 → Reuse Fast Path 零改动，**直接结束，不 dispatch 任何 Skill**。
    - **再定复杂度**：调 `bash shared/scripts/complexity-gate.sh "<需求>"` → simple/medium/complex。
    - **Gate 是唯一路由入口**：orchestrator 禁止绕过 Gate 直接 dispatch Skill；每个 pipeline 都必须由 Gate 选定。
    - **路径 ≠ 命名 pipeline**：Gate 决定「路径」（几个 skill + 深度，见 complexity-gate「路由 → 命名 pipeline 映射」），workflow-library 的命名 pipeline 是「场景参考」。以路径为准，命名 pipeline 只作展示参考。

1. `@adapter:filesystem.read runtime/registry/workflow-library.yaml` → 列出所有可用 pipeline
2. 读 `runtime/registry/capabilities.yaml` → 验证 pipeline 中每个 Skill 的 availability
3. 读 `.project-runtime/state.json`（若存在）→ 了解项目当前状态
4. 展示 pipeline 选项给用户（**Gate 选定的路径置顶**，其余折叠为「其他」）：

```
Gate 判定: [Reuse Fast Path | Quick | Standard | Full]（复杂度: X）
可用的 Pipeline（路径为准，命名 pipeline 仅参考）:
1. ★ Quick Path         — generator → verify（Gate 选定，minimal）
2. Standard Path        — planner → generator → reviewer（standard）
3. Full Path            — analyzer → ... → reviewer（full）
参考命名 pipeline: quick-change / analyze-plan-build / full-sdlc（与路径非一一对应，见 complexity-gate 映射表）
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
