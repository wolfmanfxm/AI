# Workflow Hint 块

生成完成报告结尾必须附带：

```markdown
## Workflow Hint

| # | capability | confidence | reason |
|---|-----------|:----------:|--------|
| 1 | {capability} | {0-100} | {一句话理由} |
| 2 | {capability} | {0-100} | {备选理由} |

> 💡 能力→技能映射见 `shared/routing.tsv`。
```

**产出 cap 规则**：
- 新建/修改 > 5 个文件 → 推荐 `code-review`（confidence: 85+），备选 `code-testing`（confidence: 70+）
- 涉及 API 对接 → 备选 `code-testing`（confidence: 75+）
- 仅 1-3 个小改动 → 推荐 `code-review`（confidence: 70+），备选 `documentation`（confidence: 50+）
- 始终最多 2 项
