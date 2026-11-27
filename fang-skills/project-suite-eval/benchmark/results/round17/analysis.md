# Round 17 分析 — 2026-11-27 改动的 5 条机制

> 问题：这次对 project-suite 的 5 条改动（planner 决策边界、tester 失败分型、reviewer 风险触发盲扫、
> 敏感面路由下限、delivery Safety Invariant + Proof）是否真的改变了 agent 行为？
> 方法：naive vs suite 双边对照，同一夹具、同一任务文本；suite 臂加载对应 skill。
> 样本：每臂 n=1。**n=1 不能判 pass**（round16 已实测「同一提示词两次结果不同」）。

## 结论先行

| 机制 | naive | suite | 判定 |
|------|-------|-------|------|
| planner 事实/决策分域 + 高影响不降级 | 直接把「短信验证」判为本期不做 | 停 CHECKPOINT，D-001 A/B 待拍板 | **方向性通过** |
| tester 失败分型 + 断言目标行为 | 目标断言 + RED + 不改源码 | 同左 + `[RED 证据]` + V1–V6 | **装饰品** |
| reviewer 风险触发独立盲扫 | 单遍，无独立第二方 | 无 BLOCKER 时仍触发，Missed 产出 2 条 | **初步通过（召回 + 修正后负对照）** |
| 敏感面路由下限 | Standard + 安全审查 | Standard + 风险 HIGH + reviewer QA | **装饰品** |
| delivery Safety Invariant + Proof | 验证清单，无不变式/证明 | 不变式 + `Proof: UNPROVEN` 单列 | **方向性通过** |

3 条出现方向性 delta，2 条被 naive 覆盖。全部需复跑才能定论。

## 设计事故：首轮 pilot 被目标项目污染

目标项目 `afc-newcore-web-frontend/.claude/skills/project-*` 是**指向套件仓的 symlink**。
首轮 naive 臂在真实项目内运行，直接读到 `complexity-gate.md` 与 reviewer `validation.md` 的反例条目，
基线作废（它的报告逐字引用了套件的反例）。

修正：正式运行把两臂放进 `/tmp/ps-eval-run1` 夹具（不含 `.claude/skills`），suite 臂用绝对路径加载 skill。
**教训：naive 基线必须沙箱隔离，suite 臂才加载 skill；否则 A/B 不成立。**

## 发现 1：planner 的决策边界是唯一干净的行为 delta

同一份 `task.md`：

- naive：「短信验证判为本期不做……记为假设 A1 书面提交产品确认」，随后继续 page-spec 与实现步骤。
- suite：停在 CHECKPOINT，产出 D-001（A 需要 / B 不需要），明确「预算耗尽不等于可假设」「不得交 Architect 代决」。

naive 把「告诉产品我们这么定了」当成了「让用户决定」，这正是改动要挡的失败模式。
这是本轮最可信的一条。

## 发现 2：reviewer 独立盲扫——召回成立，成本闸门在真实项目失效

**召回**（真实项目 pilot，BLOCKER=0）：suite 以「one-way：权限与认证边界」+「影响节点>5」触发独立 QA，
Missed 找到 M1（工作流守卫不透传 prevMenuPath）、M2（SELF_ROUTE 可能 403）——
两条主审查都没报。隔离子集里 suite 也产出了 Independent QA 与 Missed。

**精确性**（真实项目负对照）：2 行按钮换位的改动，`graph.json` 模块级 `findImpacted` 返回 7 个消费者节点，
>5 → 审查强度 HIGH → 独立 QA 照样触发。而在**没有 graph 的夹具**里负对照「正确跳过」——
夹具掩盖了真实环境的问题。

→ 机制「该触发时触发」成立；「不该触发时不触发」在真实项目**不成立**。
`graph > 5` 是模块级粗粒度信号，不适合当 QA 成本闸门。

**修正与复测（同日）**：从 QA 触发中移除 `graph>5`（graph 仍用于审查深度），保留
Risk=HIGH / one-way / BLOCKER>0 / 文件>10。同一条真实项目负对照复测：graph 返回 **130** 个节点，
但不再计入触发，四条条件均未命中 → `[QA SKIPPED: 未命中触发条件]`，PASS。
精确性修正 1 次复测生效；召回侧（one-way）未改动，仍由 pilot 的 BLOCKER=0 阳性证据支撑。

## 发现 3：tester 与 routing 是装饰品

- tester：naive 直接写目标断言（`toBe('0.5')`）、跑出 RED、不改源码、定位根因；
  suite 多出的只有 `[RED 证据]` 标签与 V1–V6 结构。**断言目标行为、跑测试、不越界已是当前模型默认行为。**
- routing：naive 判 Standard 并主动要求安全审查（「文件少 ≠ 风险低」）；suite 的增量是显式风险 HIGH
  与固定调度。两者最终路径一致。**价值是一致性/可追溯，不是召回。**

## 发现 4：Safety Invariant + Proof 成立，但只测了「缺失」方向

naive 给的是「发布前应验证……」清单；suite 给出 Safety Invariant（新 key 优先 + 旧 key 回退 + 旧写不覆盖新值）、
`Proof: UNPROVEN`（变更未落地）、以及「UNPROVEN 单列、不计入 PASS」。
**naive 的清单没有被标成「未执行」**——这正是要挡的「看起来验证了」。

未测：当变更真实存在、且能执行 Proof 时，agent 是否会真的跑同一条命令，而不是继续写 UNPROVEN。
下一轮需要构造一个可执行的 one-way 变更。

## 发现 5：suite 臂多数是「读 skill 文件」，不是「Skill 工具加载」

与 round16 的「加载随机性」叠加：本轮 suite 臂的报告多写「按 project-planner 走 / 读取 SKILL.md」，
少数写「调用 Skill 工具」。两者对机制内容等价，但对**真实部署行为**不等价。
本轮的 suite 证据应理解为「遵循了规则文本」，不是「Host 成功加载了 skill」。

## 判定与下一步

- **repeatability：全部 1/1，未达 ≥2。**
- 要升级为 `pass`，下一轮至少需要：
  1. 同场景每臂 2 次，固定夹具与隔离；
  2. reviewer 的 QA 触发已移除 `graph>5`，负对照复测通过（1 次）；仍需重复，并补一次「移除后仍能因 one-way 触发」的阳性复测；
  3. reviewer suite 臂禁止从夹具外补读文件；
  4. delivery 用一个可执行的 one-way 变更，验证 Proof 真的被执行，而不是只产出 UNPROVEN。
- 在此之前，台账只记 `pass-preliminary` / `decorate` / `inconclusive`，不写 `pass`。
