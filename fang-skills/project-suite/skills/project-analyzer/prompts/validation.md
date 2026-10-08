# Validation — Analyzer

> @template: validation
> 新增 Extractor 完整性 + Candidate→Verify 链路 + Evidence Score 检查

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 10 Extractors 全部返回 | 每个 Extractor 有对应 `candidates/` 产出 | 返回 Execution 补跑缺失 Extractor |
| V2 | Verifier 已判定所有 Candidate | 每个 Candidate 有 `verdict: Accepted/Rejected` | 返回 Verifier 补判定 |
| V3 | Evidence Score 完整 | 每个 Claim 标注 Confidence + Occurrences + Evidence 路径 | 标注 `[MISSING EVIDENCE]` |
| V4 | Rejected 已存档 | `candidates/rejected/` 含被拒 Candidate + rejection-reason | 标注缺失 |
| V5 | index.md 链接可达 | 所有 `[[link]]` 目标文件存在 | 标注 `[DEAD LINK]` |
| V6 | Knowledge Graph 连通 | index.md 中至少 80% 节点有 `→` 或 `←` 关系 | 标注孤立节点 |
| V7 | **契约完整性** | `bash shared/scripts/check-kb-contract.sh .project-knowledge` — 断言契约声明的**全部**目录 + 6 个固定根产物在位（清单从契约派生，不在此列举） | **🔴 阻断**：Exit 1 → 补跑缺失维度，不可 Exit |
| V8 | **项目入口** | `bash shared/scripts/check-claude-md.sh .` — 断言 `<项目根>/.claude/CLAUDE.md` 存在（大小写精确）+ 含 `.project-knowledge/index.md` 指针 + `kb-stats` 标记与本次 `statistics.json` 一致 | **🔴 阻断**：Exit 1 → 回 Finish 步骤 13 补齐，不可 Exit |

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

- 无 CRITICAL 发现
- Accepted Rate ≥ 70%（低于则可能是 Extractor 质量问题）
- **V7 契约完整性 Exit 0** —— V1–V6 是「知识质量」（失败可标注、可带债交付），V7 是「产出是否成型」
  （失败**阻断**，无中间态）。V7 未过 → 不可声明验证通过，回到 Execution 补跑缺失维度。
- **V8 项目入口 Exit 0** —— V7 查知识在 `.project-knowledge/` **内部**是否成型，V8 查它是否
  **送达到 agent**（`.claude/CLAUDE.md` 是 Claude Code 的自动加载通道）。二者互补：
  缺 V7 = 知识链断在结构，缺 V8 = 知识链断在入口——**知识库齐全但没人被自动告知**。
