# Execution — Analyzer

> @engine: execution
> v2.0: Multi-Extractor 架构 — 10 个专业化提取器 + Verifier + Knowledge Builder

## Actions

### Phase 1: Parallel Extraction（10 Extractors）

并行 spawn 10 个 Extractor agent，每个只提取一种知识：

| # | Extractor | Prompt | 产出 |
|---|-----------|--------|------|
| 1 | Directory | [extractors/directory.md](extractors/directory.md) | `candidates/directory.md` |
| 2 | Framework | [extractors/framework.md](extractors/framework.md) | `candidates/framework.md` |
| 3 | Architecture | [extractors/architecture.md](extractors/architecture.md) | `candidates/architecture.md` |
| 4 | Pattern | [extractors/pattern.md](extractors/pattern.md) | `candidates/patterns/*.md` |
| 5 | Convention | [extractors/convention.md](extractors/convention.md) | `candidates/conventions/*.md` |
| 6 | Glossary | [extractors/glossary.md](extractors/glossary.md) | `candidates/glossary.md` |
| 7 | Decision | [extractors/decision.md](extractors/decision.md) | `candidates/decisions.md` |
| 8 | Risk | [extractors/risk.md](extractors/risk.md) | `candidates/risks.md` |
| 9 | AntiPattern | [extractors/antipattern.md](extractors/antipattern.md) | `candidates/antipatterns.md` |
| 10 | Principle | [extractors/principle.md](extractors/principle.md) | `candidates/principles.md` |

每个 Extractor 输出带 Evidence Score 的 Candidate。Agent 协调规则同 v1：禁止提前返回 → 全部完成后一次性写入 → 验证 ≥100 bytes。

### Phase 2: Candidate Verification

→ [prompts/verifier.md](verifier.md)

对每个 Candidate 执行 Triple Verify：
1. **存在性** — Claim 中的文件路径/行号是否真实存在？
2. **频率** — Occurrences 计数是否准确？
3. **反例** — 是否存在 Claim 不成立的反例？

判定：全部 3 项 + Occur ≥3 → ✅ Accepted → 进入 Phase 3
      发现反例 >50% → ❌ Rejected → `candidates/rejected/`

### Phase 3: Knowledge Assembly

→ [prompts/knowledge-builder.md](knowledge-builder.md)

合并 Accepted Candidates → 生成最终 `.project-knowledge/` 产出 + Evidence Score Section。

### Phase 4: INDEX Generation

→ [prompts/index-generator.md](index-generator.md)

生成 Zettelkasten 风格 `INDEX.md` — 可导航的知识链接图。

## Exit

- 10 个 Extractor 全部返回结果
- Verifier 已判定所有 Candidate
- Knowledge Builder 已组装最终产出
- INDEX.md 已生成
