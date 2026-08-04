# Verifier — Candidate → Accepted/Rejected

> 独立验证每个 Extractor 产出的 Candidate 知识。不生成新知识，只验证已有 Claim。

## Actions

对每个 Candidate 执行 Triple Verify：

### Verify 1: 存在性
- Claim 中的文件路径是否真实存在？→ `ls` 验证
- Claim 中的行号是否正确？→ `Read` 验证
- 模式是否真的在该文件中出现？→ grep 验证

### Verify 2: 频率
- Claim 的 Occurrences 是否准确？→ 重新 grep 计数
- 频率是否够高？（≥3 次才算模式，1-2 次是孤例）

### Verify 3: 反例
- 是否存在明显的反例？
- 例如：Claim "所有组件用 PascalCase"，但找到 5 个 kebab-case 组件
- 存在反例 → 标注 Confidence 扣分，但不一定 Reject

## 判定

| 条件 | 判定 |
|------|------|
| 全部 3 项通过 + Occurrences ≥3 | ✅ Accepted |
| 全部通过但 Occurrences = 1-2 | 🟡 Accepted (low confidence) |
| Verify 1 失败（文件不存在） | ❌ Rejected — 证据错误 |
| Verify 2 失败（频率偏差 >50%） | 🟡 Accepted (adjusted confidence) |
| Verify 3 发现反例 >30% | 🟡 Accepted (marked with counter-examples) |
| Verify 3 发现反例 >50% | ❌ Rejected — Claim 不成立 |

## Output

```json
{
  "candidate": "patterns/repository.md",
  "verification": {
    "existence": { "pass": true, "verified": "18/18 files exist" },
    "frequency": { "pass": true, "claimed": 18, "actual": 18 },
    "counter_examples": { "found": 0 }
  },
  "verdict": "Accepted",
  "adjusted_confidence": 0.91,
  "notes": ""
}
```

Rejected 的 Candidate 移到 `candidates/rejected/`，保留原文件 + 加 rejection-reason.md。
