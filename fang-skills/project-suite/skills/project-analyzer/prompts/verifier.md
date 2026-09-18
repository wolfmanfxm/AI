# Verifier — Candidate → Accepted/Rejected

> 独立验证每个 Extractor 产出的 Candidate 知识。不生成新知识，只验证已有 Claim。

## Actions

对每个 Candidate 逐项执行以下 Verify：

> ⚠️ **本文件是唯一保留自有检查表的 verifier**（2026-09-18 收敛的例外）。
> 其余 8 个 skill 的 verifier 已改为引用 `validation.md` 的检查项。analyzer 不同——
> `validation.md` 检查的是**流程**（Extractor 是否全跑、Candidate 是否已判定、INDEX 是否可达），
> 下表检查的是**知识质量**（存在性/频率/反例/预测力/非显而易见性/契约字段）。两者不同对象，合并会混层。
> **代价**：这 6 项仍是一份独有清单——改它不必同步别处，但也不受「检查项单一来源」的保护。

| # | 校验项 | 判据 | 不通过时 |
|---|--------|------|---------|
| V1 | 存在性 | 文件路径与行号真实存在，模式确实出现在该处 | 修正引用；文件不存在 → ❌ Rejected |
| V2 | 频率 | Occurrences 与重新 grep 计数一致，且 ≥3（1-2 次是孤例） | 按偏差比例降权；偏差 >50% → ❌ Rejected |
| V3 | 反例 | 抽样未发现明显反例 | 按反例比例降权；>50% → ❌ Rejected |
| V4 | 预测力 | 能回答一个代码没有显式说明的问题 | -0.10，标注 `[DESCRIPTIVE]` |
| V5 | 非显而易见性 | 不是任何有经验开发者一眼可见的常识 | -0.15，标注 `[OBVIOUS]`，INDEX.md 降权 |
| V6 | 契约字段齐备 | 目标目录要求的 `statement` / `constraint` 能给出**可注入**的一句 | ❌ Rejected——不许拿标题或描述凑数 |

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

### Verify 6: 契约字段齐备（Producer 侧硬要求）

按 Candidate 的**目标目录**（见 [knowledge-builder.md](knowledge-builder.md) 的 Coverage Gate）对照
[shared/schemas/knowledge-directories.yaml](../../../shared/schemas/knowledge-directories.yaml) 的 `required_frontmatter`：

| 目标目录 | 必需字段 | 判定方式 |
|---------|---------|---------|
| `patterns/` `components/` `api/` | `statement` | Candidate 能否给出**一句可直接注入**的摘要？（Resolver hydrate 直接抽它进 `context-package.json`，Generator 不读正文） |
| `decisions/` | `constraint` | Candidate 能否给出**一句硬约束**？（Compiler 硬校验，缺即拒绝生成 index，整条知识链中断） |
| 其余目录 | 无 | 跳过 |

**产不出就是没通过**，不许拿标题或描述凑数：

- 摘要写成「关于 X 的若干说明」这类**不可注入**的空话 → ❌ 视为产不出 `statement`
- 决策只写了背景与方案对比，抽不出「必须 / 禁止 …」的硬约束 → ❌ 视为产不出 `constraint`

> 为什么放在 Verifier：`statement` / `constraint` 缺失**都不报错**——`statement` 缺失时 Resolver 静默退化为标题拼接，
> `constraint` 缺失时 Compiler 直接拒绝生成 index。Candidate 阶段是唯一能提前拦住的地方。
> 缺口实证：真实项目 `statement` 合规率 **0/12**，正是从这里漏过去的。

## 判定

| 条件 | 判定 |
|------|------|
| 全部 6 项通过 + Occurrences ≥3 | ✅ Accepted |
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
| Verify 6 产不出必需字段（`statement` / `constraint`） | ❌ Rejected → `candidates/rejected/`，reason 记「candidates 缺契约字段 `<field>`」——缺契约字段的知识**不得进入 knowledge** |

**Adjusted 但未 Rejected 的 Candidate**：在 Output 中列出 adjusted 清单，标注原 confidence → 调整后 confidence + 原因。不得静默调整。

## Output

```json
{
  "candidate": "patterns/repository.md",
  "verification": {
    "existence": { "pass": true, "verified": "18/18 files exist" },
    "frequency": { "pass": true, "claimed": 18, "actual": 18 },
    "counter_examples": { "found": 0 },
    "contract_fields": { "required": ["statement"], "present": true }
  },
  "verdict": "Accepted",
  "adjusted_confidence": 0.91,
  "notes": ""
}
```

Rejected 的 Candidate 移到 `candidates/rejected/`，保留原文件 + 加 rejection-reason.md。
