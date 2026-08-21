# Discovery — Planner

> @template: discovery

## Actions

0. **Context Resolver** — 读 context-package.json（rules[]/knowledge[]/guidance[]），先拿到本项目的约束与知识 → [Context Resolver](../../../runtime/contracts/context-resolver.md)

1. **Project Constraints（blocking）** — 加载 context-package.json 的 rules[] 全部 blocking 约束（rules + project-scope decisions）。这是硬约束，后续 Reuse/Decision/Task 都据此判断。

2. **Relevant Knowledge（recommended）** — 加载 context-package.json 的 knowledge[]（patterns/components/api），用于 Reuse Analysis。

3. **Experience / Playbooks（advisory）** — 加载 context-package.json 的 guidance[]（含 task-scope decisions），用于提高方案质量，非强制。

4. **Code Audit** → [prompts/code-audit.md](code-audit.md)：标注 `[已实现]` / `[部分实现]` / `[未实现]` → Interview 前先知道项目有什么。

5. **Completeness Check** → [prompts/completeness-check.md](completeness-check.md)：
   - 多维度评分（goal/scope/constraints/knowledge）→ planning_confidence
   - Code Audit 已发现 + Context Resolver 已查询 → 计入 knowledge 维度
   - ≥0.9 → 直接 Plan | 0.7-0.89 → ≤2 questions | 0.5-0.69 → ≤3 questions | <0.5 → ≤5 questions + Assumption

6. 读用户输入 + 上游 `PLAN.md` / `ARCHITECTURE.md`（若存在）

7. 一句话总结 **Goal** + 划定 **Scope** 边界（显式列出 包含/不包含）

8. CHECKPOINT — 展示 Goal + Scope

## Exit

- Goal 一句话已确认 + Scope 边界已确认
- 用户已点确认

## Failure

| Condition | Action |
|-----------|--------|
| 无任何需求输入 | 🔴 BLOCKED |
| `context.json` 缺失 | 从 `.project-knowledge/` 提取 |
| `context-package.json` 缺失 | 兜底直读 `.project-knowledge/rules/`、`decisions/`（project-scope，非 `ARCHITECTURE-*`）、`experience/` |

## CHECKPOINT

🔴 CHECKPOINT — 展示 Goal + Scope，用户确认后进入 Execution
→ [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)
