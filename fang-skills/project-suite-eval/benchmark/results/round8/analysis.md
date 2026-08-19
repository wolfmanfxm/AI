# Round 8 分析 — Protocol 非 Engine 定位修正验证

> 验证「Protocol 非 Engine」定位修正（round8 改动）是否真生效。
> 本轮改动性质：命名/语义清理。重点验证「改声明后，agent 行为是否跟着变」，而非只改了 yaml。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| #1 | next_action: stop → handoff | ✅ 生效 | N8-M1：`convergence_next_action: "handoff"`，`used_old_stop: false` |
| #2 | auto-promote → human confirmation | ✅ 生效 | N8-ANA：`auto_promoted: false`，唯一 personal 候选 `pending_human_confirmation`，未写 Vault |
| #3 | orchestrator 去 auto-advance | 🟡 静态收口 | 无 pipeline-execution 残留（本轮未单独跑 orchestrator 任务） |
| #4 | 目录改名（workflow-protocol / mechanisms） | ✅ 无回归 | agent 正常读到改名后的路径，无「找不到 workflow-engine」报错 |

## #1 handoff 语义验证（生效）

**假设**：改 handoff 后，agent 收尾产出 `handoff`（交下游）而非旧 `stop`。

**结果**：N8-M1 的 agent 明确产出：
- `convergence_next_action: "handoff"`
- `used_old_stop: false`

**结论**：语义改动真被消费了。agent 读 stage 模板 + convergence 原语后，用了新字段 `handoff`。这是「改声明→改消费」的正面例子——和 round5 #1（改声明没改消费）形成对照，因为这次**声明层（convergence.md + stage 模板）和消费层（agent 读的 prompts）都同步改了**。

## #2 auto-promote 回归验证（生效）

**假设**：background 加 promotion_confirm 后，agent 不自动晋升 personal 知识。

**结果**：N8-ANA 的 agent：
- 产出 7 条候选知识评分（1 promote_candidate / 5 keep_project / 1 reject）
- `auto_promoted: false`
- 唯一 personal 候选（docx-preview）标记 `pending_human_confirmation`，**未写 Vault**
- 评分建议只落 `candidates/`（中间产物），未触碰 Vault/Knowledge/

**结论**：行为改动真生效。agent 读 promotion-reviewer.md 的「人工 Review 边界」后，执行了「只产建议，等人工确认」。这验证了「personal promotion = human confirmation」的语义统一。

## 关键观察：本轮是「改声明→改消费」的正面闭环

对比历史：
- round5 #1（context_contract 语义化）：改声明**没**改消费 → agent 行为不变 → 暴露问题
- round6 #3（convergence）：改声明**没**改消费 → 悬空 → 修复后复验生效
- **round8 #1/#2：改声明+改消费同步 → agent 行为跟着变 → 一次通过**

规律确认：**要让语义改动生效，必须「声明层 + 消费层」同步改**。round8 的两个改动（handoff、auto-promote）之所以一次通过，是因为改动时就同步改了声明（convergence.md / background.yaml）+ 消费（stage 模板 / promotion-reviewer.md），没有像 round5 #1 那样只改 yaml 字段名。

## 建议下一步

1. **#3 orchestrator 单独验证（P2）**：本轮未单独跑 orchestrator 任务，auto-advance 改动只做了静态收口。要验证「orchestrator 建议而非自动执行」，需跑一个 pipeline 编排任务。
2. **#4 目录改名的软引用（P2）**：虽然 agent 没报错，但 70+ 文件的路径改名，建议在真实长任务（跨多 skill）里再验一次，确认没有深层引用遗漏。

## 本轮结论

Protocol 非 Engine 定位修正的核心语义改动（handoff、auto-promote）**真实生效**，且是「改声明+改消费同步」的正面闭环。这印证了贯穿整个 benchmark 的规律：**消费端才是决定行为的点，改声明必须同步改消费。**

---

## 补测结果（追加，round8 第二部分——完成剩余 P2）

补测了 #3（orchestrator 去 auto-advance）和 #4（目录改名软引用）。

### #3 orchestrator 去 auto-advance → 生效

| 信号 | 结果 |
|------|------|
| `auto_advanced` | false（未级联执行所有 skill） |
| `decision_boundary_respected` | true（在 planner 决策边界暂停） |
| `suggested_next_skill` | project-planner（建议而非自动执行） |

**结论**：orchestrator 正确地「建议编排」而非「自动执行」。agent 读 orchestrate.md 的 Decision-Boundary Checkpoint 后，在首个决策边界（planner）暂停给建议，未级联执行。这验证了「Pipeline = Protocol，Host 决定是否执行」的定位。

### #4 目录改名软引用 → 无回归

| 信号 | 结果 |
|------|------|
| `path_resolution_ok` | true |

**结论**：agent 正常读取 workflow-protocol、pipeline-orchestrator、runtime/mechanisms 等改名后的路径，无「找不到 workflow-engine」报错。目录改名（70+ 文件）无深层引用遗漏。

### 补测发现的语义间隙（新问题，非本轮改动引入）

agent 记录了一个真实问题：**complexity-gate 的 4 档路由（Reuse/Quick/Standard/Full）与 workflow-library 的 5 个命名 pipeline（full-sdlc/analyze-plan-build/quick-change/refactor-cycle/knowledge-refresh）并非一一对应**。

具体：Standard Path（planner → generator → reviewer）在 workflow-library 中无同名 pipeline，最接近的 `analyze-plan-build` 多了 analyzer + architect。medium 任务需「按复杂度门收敛后再映射到命名 pipeline」，这个映射关系当前是隐式的，容易让 agent 困惑。

**这是「复杂度门路由」和「命名 pipeline 库」之间的契约缝隙**，值得后续修（在 workflow-library 补 Standard Path 定义，或在 complexity-gate 明确映射关系）。但它不是本轮「Protocol 非 Engine」改动引入的，是历史遗留。

## 最终结论（round8 完整）

| # | 改动 | 判定 |
|---|------|------|
| #1 | handoff 语义 | ✅ 生效 |
| #2 | auto-promote → human confirmation | ✅ 生效 |
| #3 | orchestrator 去 auto-advance | ✅ 生效（补测） |
| #4 | 目录改名 | ✅ 无回归（补测） |

4 项全部验证通过。Protocol 非 Engine 定位修正的语义改动**全部真实生效**，且都是「改声明+改消费同步」的正面闭环。
