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

### Verify 4: 预测力（cangjie V2）
- 这个知识**能否回答一个代码没有显式说明的问题**？
- 例如：Claim "项目使用 Repository Pattern" → 能预测"新增数据源时只需加一个 Repository 文件"
- 不能预测 → 扣分（-0.10）——说明只是描述性而非推理性知识
- 能预测 → 加分（+0.05）——说明抓住了底层原理

### Verify 5: 非显而易见性（cangjie V3）
- 这个知识**是否任何有经验的开发者都能一眼看出**？
- 例如："项目使用 Vue 3" → ❌ 太显然，package.json 第 3 行就能看到
- 例如："项目禁止在 composable 外使用 useState" → ✅ 非显然，来自代码审查经验
- 太显然的知识 → 扣分（-0.15），标注 `[OBVIOUS]` —— 降低其在 INDEX.md 中的排序权重
- 非显然的知识 → 加分（+0.05），标注 `[INSIGHT]` ——在 INDEX.md 中提升排序

## 判定

| 条件 | 判定 |
|------|------|
| 全部 5 项通过 + Occurrences ≥3 | ✅ Accepted |
| 全部通过但 Occurrences = 1-2 | 🟡 Accepted (confidence -0.20) |
| Verify 1 失败（文件不存在） | ❌ Rejected → `candidates/rejected/` |
| Verify 2 频率偏差 10-30% | 🟡 Accepted (confidence -0.10) |
| Verify 2 频率偏差 30-50% | 🟡 Accepted (confidence -0.25), 标注 `⚠️ FREQUENCY GAP` |
| Verify 2 频率偏差 >50% | ❌ Rejected → `candidates/rejected/` |
| Verify 3 发现反例 10-30% | 🟡 Accepted (confidence -0.10), 标注 counter-examples |
| Verify 3 发现反例 30-50% | 🟡 Accepted (confidence -0.25), 标注 `⚠️ COUNTER EXAMPLES` |
| Verify 3 发现反例 >50% | ❌ Rejected → `candidates/rejected/` |
| Verify 4 不能预测 | 🟡 Accepted (confidence -0.10), 标注 `[DESCRIPTIVE]` |
| Verify 5 太显而易见 | 🟡 Accepted (confidence -0.15), 标注 `[OBVIOUS]` — INDEX.md 降权 |

**Adjusted 但未 Rejected 的 Candidate**：在 Output 中列出 adjusted 清单，标注原 confidence → 调整后 confidence + 原因。不得静默调整。

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
