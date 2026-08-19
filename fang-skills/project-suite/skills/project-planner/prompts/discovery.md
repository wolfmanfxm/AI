# Discovery — Planner

> @template: discovery

## Actions

0. **Code Audit** → [prompts/code-audit.md](code-audit.md)：
   标注 `[已实现]` / `[部分实现]` / `[未实现]` → Interview 前先知道项目有什么。

1. **Context Resolver** — 查询 graph.json → 注入 curated knowledge：
   → [Context Resolver](../../../runtime/contracts/context-resolver.md)

2. **Completeness Check** → [prompts/completeness-check.md](completeness-check.md)：
   - 多维度评分（goal/scope/constraints/knowledge）→ planning_confidence
   - Code Audit 已发现 + Context Resolver 已查询 → 计入 knowledge 维度
   - ≥0.9 → 直接 Plan | 0.7-0.89 → ≤2 questions | 0.5-0.69 → ≤3 questions | <0.5 → ≤5 questions + Assumption

3. 结构化查询项目知识：`@adapter:knowledge.query --type component,api,pattern --scope project`

4. 读用户输入 + 上游 `PLAN.md` / `ARCHITECTURE.md`（若存在）

5. 一句话总结 **Goal** + 划定 **Scope** 边界（显式列出 包含/不包含）

6. CHECKPOINT — 展示 Goal + Scope

## Exit

- Goal 一句话已确认 + Scope 边界已确认
- 用户已点确认

## Failure

| Condition | Action |
|-----------|--------|
| 无任何需求输入 | 🔴 BLOCKED |
| `context.json` 缺失 | 从 `.project-knowledge/` 提取 |

## CHECKPOINT

🔴 CHECKPOINT — 展示 Goal + Scope，用户确认后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
