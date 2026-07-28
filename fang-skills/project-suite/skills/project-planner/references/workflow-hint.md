# Workflow Hint 块

PLAN.md 结尾必须附带以下结构，让用户基于信息决策下一步，而非硬编码命令：

```markdown
## Workflow Hint

| # | capability | confidence | reason |
|---|-----------|:----------:|--------|
| 1 | {capability} | {0-100} | {一句话理由，为什么推荐} |
| 2 | {capability} | {0-100} | {备选，什么情况下选它} |

> 💡 这是建议不是命令。高 confidence 项可直接执行，低 confidence 项建议人工确认。
> 能力→技能映射见 `shared/routing.tsv`。
```

**产出 cap 规则**：
- plan 包含未 resolve Decision → 推荐 `architecture-review`（confidence: 75+）
- plan 全 resolved → 推荐 `code-generation`（confidence: 85+）
- plan 含高风险项 → 推荐 `architecture-review`（confidence: 65+）作为备选
- 始终最多推荐 2 项，超过则取 confidence 最高的 2 项
