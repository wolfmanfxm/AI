# Validation — Analyzer v2.0

> @template: validation
> v2.0: 新增 Extractor 完整性 + Candidate→Verify 链路 + Evidence Score 检查

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 10 Extractors 全部返回 | 每个 Extractor 有对应 `candidates/` 产出 | 返回 Execution 补跑缺失 Extractor |
| V2 | Verifier 已判定所有 Candidate | 每个 Candidate 有 `verdict: Accepted/Rejected` | 返回 Verifier 补判定 |
| V3 | Evidence Score 完整 | 每个 Claim 标注 Confidence + Occurrences + Evidence 路径 | 标注 `[MISSING EVIDENCE]` |
| V4 | Rejected 已存档 | `candidates/rejected/` 含被拒 Candidate + rejection-reason | 标注缺失 |
| V5 | INDEX.md 链接可达 | 所有 `[[link]]` 目标文件存在 | 标注 `[DEAD LINK]` |
| V6 | Knowledge Graph 连通 | INDEX.md 中至少 80% 节点有 `→` 或 `←` 关系 | 标注孤立节点 |
| V7 | 旧格式兼容 | 保留 `architecture/` `components/` `api/` `patterns/` 目录结构 | 标注缺失目录 |

## QA Agent

全量分析 → spawn 独立 agent，检查 Extractor 间一致性：
- Architecture Extractor 的模块列表与 Directory Extractor 的目录树是否一致？
- Pattern Extractor 的模式名与 Convention Extractor 的命名规范是否一致？
- Glossary 的术语是否在 API/类型定义中真实出现？

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Output

`validation-report.md` + Candidate Pipeline 健康度：
- Candidates extracted: N
- Accepted: N (%) 
- Rejected: N (%)
- Evidence Score avg: X.XX

## Exit

无 CRITICAL 发现；Accepted Rate ≥ 70%（低于则可能是 Extractor 质量问题）
