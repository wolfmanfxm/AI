# Validation — Architect

> @template: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | ADR 决策链完整 | 问题→候选方案→选择→理由 四段不缺 | 返回 Execution 补全 |
| V2 | 对比矩阵完整 | 候选方案 ≥2，维度 ≥3，分差有说明 | 补全矩阵或标注原因 |
| V3 | 现状核实准确 | `[已实现]` 标注的模块路径实际存在 | 修正标注 |
| V4 | API 契约可实施 | 每个 endpoint 有 method/path/request/response | 补全缺失字段 |
| V5 | 模块耦合合理 | 跨层依赖（view→infrastructure）已标注原因 | 标注架构风险 |
| V6 | ADR 四段完整 | 问题→候选方案→选择→理由 不缺 | 返回补全 |
| V7 | 决策成本门 | low-impact（可逆/局部/单模块）→ 1 方案 + reason 即可；high-impact（不可逆/跨模块/影响下游）→ ≥2 方案 + ≥3 维度 | 🟡 补全或标注原因 |
| V8 | 方案自洽 | 技术选型、模块设计、API 间无矛盾 | 🟡 标注矛盾 |
| V9 | 分差有理 | 对比矩阵分差 <10% 时有充分说明 | 🟡 标注风险 |
| V10 | Graph 一致 | 设计引用的模块/API 在 graph.json 中存在；新增模块前先走 [Reuse Ladder](../../../shared/primitives/reuse-check.md)（可扩展已有模块就不新建） | 修正引用 |
| V11 | 术语一致 | 设计引入的术语与 `.project-knowledge/architecture/glossary.md` 的核心术语表一致；**新增页面/API 的 artifact 命名须匹配其「产物 artifact」表的 `naming` 前缀**（或由 entity×action 组合合法派生） | ⚠️ 术语冲突：现有定义 ≠ 新假设 → 阻断，追问澄清 |

## QA Agent

**触发条件**：综合设计（含多个设计领域）

**方法**：spawn 独立 agent，仅读 ARCHITECTURE.md（不含对话上下文），检查：
1. 方案自洽性 — 技术选型、模块设计、API 契约之间是否有矛盾
2. 遗漏 — 是否有应该考虑的候选方案被忽略
3. 非功能性需求覆盖 — 安全/性能/可扩展性是否被考虑

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Exit

无 CRITICAL 发现（决策链完整、对比充分、无方案自相矛盾）
