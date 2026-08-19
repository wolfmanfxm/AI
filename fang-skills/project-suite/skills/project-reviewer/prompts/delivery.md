# Delivery — Reviewer

> @template: delivery

## Actions

写入 `.project-knowledge/reports/REVIEW-<topic>.md`：

1. **问题列表**（按 BLOCKER → HIGH → MEDIUM → LOW 排序）
2. **PRAISE**（值得学习的代码）
3. **AC 对照表**（每条 AC 的 ✅/❌/⚠️ 状态）
4. **审查结论**（PASS / NEEDS_FIX / BLOCKED）
5. **Validation notes**（元审查结果）
6. **QA findings**（若有 QA Agent 发现）

## Exit

- `REVIEW-<topic>.md` 写入成功
- state.json 更新（confidence + history）

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 → 仍失败标注 `❌ FAILED` |
