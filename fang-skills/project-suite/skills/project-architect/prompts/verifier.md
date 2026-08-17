# Verifier — Architect

> 独立验证 Candidate ADR。不参与设计过程。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | ADR 四段完整 | 问题→候选方案→选择→理由 不缺 | 返回补全 |
| V2 | 决策成本门 | low-impact（可逆/局部/单模块）→ 1 方案 + reason 即可；high-impact（不可逆/跨模块/影响下游）→ ≥2 方案 + ≥3 维度 | 🟡 补全或标注原因 |
| V3 | 现状核实准确 | `[已实现]` 模块路径存在 | 修正标注 |
| V4 | API 契约完整 | 每个 endpoint 有 method/path/request/response | 补全字段 |
| V5 | 方案自洽 | 技术选型、模块设计、API 间无矛盾 | 🟡 标注矛盾 |
| V6 | 分差有理 | 对比矩阵分差 <10% 时有充分说明 | 🟡 标注风险 |
| V7 | Graph 一致 | 设计引用的模块/API 在 graph.json 中存在；新增模块前先走 [Reuse Ladder](../../../shared/primitives/reuse-check.md)（可扩展已有模块就不新建） | 修正引用 |
| V8 | Domain 一致 | 设计引入的术语与 vocabulary.yaml 的 confirmed 术语一致；**新增页面/API 的 artifact 命名须匹配 artifacts 的 naming 前缀**（或由 entity×action 组合合法派生） | ⚠️ Domain conflict：现有定义 ≠ 新假设 → 阻断，追问澄清 |

## 判定

| 条件 | 判定 |
|------|------|
| V1-V8 全部通过 | ✅ Accepted |
| V1 失败(ADR 不完整) | ❌ Rejected |
| V5 失败(方案自相矛盾) | ❌ Rejected |
| V8 失败(domain 冲突) | ❌ Rejected — 与 confirmed domain 术语冲突，需澄清 |
| V3-V7 部分失败 | 🟡 Accepted + adjusted confidence |

## Evidence Format

```yaml
candidate: ARCHITECTURE-interest-rate.md
verdict: accepted
confidence: 0.85
evidence:
  decisions: 6
  adr_complete: "6/6 (100%)"
  matrix_dimensions: { perf: true, ecosystem: true, familiarity: true, community: true }
  alternatives_per_decision: { min: 2, max: 4, avg: 2.8 }
  code_audit_verified: "12/12 annotations confirmed"
  api_endpoints: 5
  graph_consistent: true
```
