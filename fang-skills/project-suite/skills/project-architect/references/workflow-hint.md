# Workflow Hint 块

ARCHITECTURE.md 结尾必须附带：

```markdown
## Workflow Hint

| # | capability | confidence | reason |
|---|-----------|:----------:|--------|
| 1 | {capability} | {0-100} | {一句话理由} |
| 2 | {capability} | {0-100} | {备选理由} |

> 💡 能力→技能映射见 `shared/routing.tsv`。
```

**产出 cap 规则**：
- ARCHITECTURE 包含完整 API 契约 → 推荐 `code-generation`（confidence: 85+）
- ARCHITECTURE 含新模块设计 → 推荐 `code-generation`（confidence: 80+），备选 `code-review`（confidence: 60+）
- 始终最多 2 项
