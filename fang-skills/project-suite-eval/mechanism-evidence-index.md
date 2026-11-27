# 机制证据索引（Mechanism → Evidence）

> 用途：project-suite 的规则文本不再携带轮次/日期；需要追溯时，从这里按**机制 ID**找到对应的
> pressure test、ledger 记录与轮次/日期。权威仍是
> [mechanism-verification-ledger.md](mechanism-verification-ledger.md)，本文件只做索引，不重复结论。

| 机制 ID | suite 规则位置 | pressure test | ledger 记录 | 轮次 / 日期 | 当前判定 |
|---|---|---|---|---|---|
| `planner-decision-boundary` | `skills/project-planner/prompts/interview.md`、`completeness-check.md` | `project-planner.yaml#P6` | 各 Skill 台账 · project-planner；round19 · 事实/决策分域 | round19 / 2026-11-27 | PASS（2/2 vs 2/2） |
| `reviewer-risk-qa` | `skills/project-reviewer/prompts/validation.md` | `project-reviewer.yaml#P5` | 各 Skill 台账 · project-reviewer；round17/18/19 | round19 / 2026-11-27 | PASS（触发 4/4；0 BLOCKER 2/2） |
| `reviewer-verifier-independence` | `skills/project-reviewer/prompts/verifier.md`、`validation.md#V9` | `project-reviewer.yaml#P5` | round18 / round19 · 环境事实 | round19 / 2026-11-27 | PASS（Agent 派生 6/6 post-fix；含交互式 2/2） |
| `tester-red-classification` | `skills/project-tester/prompts/execution.md`、`unit-test.md` | `project-tester.yaml#P5` | 各 Skill 台账 · project-tester；round19 | round19 / 2026-11-27 | DECORATE（2/2 等价） |
| `delivery-safety-invariant` | `skills/project-releaser/prompts/delivery.md`、`shared/primitives/delivery-evidence.md` | `project-releaser.yaml#P1` | 各 Skill 台账 · 跨 Skill；round18/19 | round19 / 2026-11-27 | DECORATE（中性 2+2；合成迁移场景） |
| `routing-sensitive-floor` | `shared/prompts/complexity-gate.md`、`shared/scripts/complexity-gate.sh` | `cross-skill-routing.yaml#R13` | 跨 Skill 机制；round19 | round19 / 2026-11-27 | L1 only（Gate 已修 + 冒烟） |
| `routing-orchestrator-r6` | `skills/pipeline-orchestrator/SKILL.md` | （R6，见 `cross-skill-routing.yaml` 说明） | round19 · B1 Routing L2 | 2026-11-27 | PASS（L2 2/2；未改 Run 契约） |
| `producer-contract-field` | `runtime/contracts/*`（Producer 契约字段） | 未建 | round12/13 仅 suite 侧 | — | UNTESTED（缺 native 臂） |
| `frontmatter-read` | `runtime/knowledge/knowledge-compiler.md` | 未建 | round13 仅真实修复 | — | UNTESTED（缺 native 臂） |

## 使用约定

- **suite 侧只写机制 ID**，不写轮次/日期；例如「证据：eval ledger · `reviewer-risk-qa`」。
- 轮次/日期只在本索引与 ledger 维护；换模型/重跑后在对应行追加，不改 suite 规则。
- 判定的范围（L2/headless/n=2、合成夹具、L1 only）必须和判定一起读，不单独引用「PASS」。
- 新增机制时，先在本表加一行，再在 ledger 写 hypothesis/证据；未建 pressure test 的标 `未建`。
