# Validation — Reviewer

> @template: validation

> reviewer 的 Validation 是**元审查** — 检查审查本身的质量

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 五轴全覆盖 | 每轴至少 1 条记录（含 PRAISE 或 PASS 标注） | 补全未覆盖轴 |
| V2 | file:line 有效 | 每个发现标注的路径+行号对应文件存在 | 修正引用 |
| V3 | AC 逐条对照 | AC 表逐条 ✅/❌/⚠️，无遗漏 | 补全遗漏 AC |
| V4 | 分级合理 | BLOCKER 有明确阻断理由（不为空且不泛泛），无 LOW 误标 BLOCKER | 调整分级 |
| V5 | Scope 边界 | 标注超出 PLAN.md `# Scope` 的变更项 | 补充 `[SCOPE CREEP]` |

## QA Agent

**触发条件**：BLOCKER >0 或变更文件 >10

**方法**：spawn 独立 agent，仅读 REVIEW.md 草稿 + 变更文件（不含对话上下文），验证：
1. 每个 BLOCKER 的判定依据在代码中确实存在
2. 修复建议是否具体可操作（"改一下"不通过）
3. 是否遗漏了明显的安全问题或逻辑错误

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Output

REVIEW.md（含 validation notes + QA findings）

## Exit

无 CRITICAL 发现（BLOCKER 判定无误、分级合理、AC 无遗漏）
