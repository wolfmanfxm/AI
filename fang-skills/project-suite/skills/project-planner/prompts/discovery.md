# Discovery — Planner

> @engine: discovery

## Actions

0. **Context Resolver** — 从用户任务提取 tags → 查询 knowledge-graph.yaml → 注入 curated knowledge（不读全部 .md）：
   → [Context Resolver](../../../runtime/contracts/context-resolver.md)
1. 结构化查询项目知识：`@adapter:knowledge.query --type component,api,pattern --scope project`
   降级：`knowledge-graph.yaml` 缺失 → 读 `context.json`
2. 读用户输入 + 上游 `PLAN.md` / `ARCHITECTURE.md`（若存在）
3. 一句话总结 **Goal** + 划定 **Scope** 边界（显式列出 包含/不包含）
4. CHECKPOINT — 展示 Goal + Scope（格式：一句话 Goal + Scope IN/OUT 清单）

## Exit

- Goal 一句话已确认
- Scope 边界已确认（IN/OUT 清单无异议）
- 用户已点确认

## Failure

| Condition | Action |
|-----------|--------|
| 无任何需求输入 | 🔴 BLOCKED — 拒绝执行 |
| `context.json` 缺失 | 从 `.project-knowledge/` 提取（读 index.md + architecture/） |

## CHECKPOINT

🔴 CHECKPOINT — 展示 Goal + Scope，用户确认后进入 Code Audit
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
