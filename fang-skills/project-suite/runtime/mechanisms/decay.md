# Knowledge Decay Engine v1.0

> 知识自动衰减。未验证/未使用的知识随时间降级，防止知识库腐化。

## Decay 规则

| 触发条件 | 动作 |
|---------|------|
| `last_verified` > 180 天 | stability -0.2, 标注 `⚠️ STALE` |
| `last_verified` > 365 天 | stability -0.4, 标记 `deprecated` |
| `last_used` > 90 天 + `reuse` < 3 | stability -0.1 |
| `last_used` > 365 天 + `reuse` = 0 | stability -0.3, 标记 `deprecated` |
| `occurrences` 跨项目下降 >50% | confidence -0.15 |

## Decay 级别

| stability | 状态 | 动作 |
|-----------|------|------|
| ≥ 0.7 | Stable | 正常使用 |
| 0.4-0.69 | Decaying | 标记 `⚠️ DECAYING`，下次 analyzer 重新验证 |
| 0.2-0.39 | Candidate | 降级为 Candidate，需要重新 Verify |
| < 0.2 | Deprecated | 标记 `deprecated: true`，移入 review queue |

## Decay 检查

`shared/scripts/check-decay.sh` — 扫描 Knowledge Vault 中所有 knowledge object 的 `decay` 字段，输出 decay 报告。

## 恢复

Decayed knowledge 被重新验证（analyzer 发现该 pattern 仍然存在 + 频率稳定）→ stability 重置为 1.0。
