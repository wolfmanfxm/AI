# Roadmap

> project-suite 演进路线图。当前 Suite v1.0 Spec / Release v1.0。project-suite 是 Protocol 非 Engine（Suite 定义协议，Host 负责执行/强制，见下状态模型）。

## 定位

> project-suite 是 **Agent SDLC Framework**，不是 Skills 集合（区别于 Superpowers 的 composable / Matt Pocock 的小 Skill 路线）。复杂度在 Framework 层（runtime/mechanisms + registry + gates + profiles + shared/primitives），Skill 保持薄（~50 行）。**新增能力 → Framework 层，不散落进 SKILL.md。**

## 复杂度按需启用（反自动化原则）

> **不要为了自动化而自动化。复杂任务才启用复杂机制。** 这是 project-suite 区别于「把 mandatory workflow / 固定 phase / grill / hooks / memory 全堆进去」的关键差异点。

```
Simple    → Skill（直接做，无额外流程税）
Medium    → Skill + Verify
Risky     → Challenge / Interview（决策风险高才追问）
Complex   → Plan + Checkpoint + Verify
Persistent knowledge → Promotion（值得跨项目才晋升）
```

**原则**：机制是「按需启用」的阶梯，不是「全部强制」的流水线。简单任务背全流程 = 流程税，这正是 round3/4 暴露、complexity-gate 要解决的。每个机制都有「何时触发」的入口（complexity-gate 的 Quick/Standard/Full、interview 的 confidence 分级、architect 的决策风险分级），而不是无差别执行。

## 状态模型（避免「假完成」）

> `[x]` 只表示「协议/实现完成」，不代表「在真实环境被 Host 强制执行」。project-suite 是 Protocol，不是 Engine——Protocol 自己没有 Enforced 能力，强制能力是 Host 的（见 [host-capability.md](../runtime/contracts/host-capability.md)）。四态标注：

| 状态 | 含义 | 当前实例 |
|------|------|---------|
| **Specified** | Protocol 已定义（有规范/契约文档） | Runtime（Protocol 非 Engine）、Convergence |
| **Implemented** | 有 reference implementation / adapter / script | Complexity Gate、Command Guard（有脚本，无真 hook） |
| **Host-Supported** | 某个 Host 能正确解释/执行（如 Claude Code Hook） | Command Guard（Claude Code PreToolUse Hook） |
| **Validated** | Benchmark 验证行为符合预期 | depth_profiles 深度、知识缺口（round4 实测） |

> 关键：**没有「Enforced」这个状态**——Suite 不假装有强制能力。强制是 Host 的 `host_capabilities`（advisory/enforced），不是 Suite 的状态。

## 版本

> **Suite v1.0 Spec / Release v1.0**。版本号只此一处，其余不重复声明。后续演进从 release 1.0 后做版本更新。

| 版本 | 日期 | 说明 |
|------|------|------|
| **Spec v1.0** | 2026-08 | 当前规范版本（SUITE_SPEC.md） |
| **Release v1.0** | 2026-08 | 当前发布版本（suite-manifest.yaml）。Knowledge Consumption 闭环 + Protocol 定位修正 |

### 历史版本（归档）

| 版本 | 日期 | 关键变化 |
|------|------|---------|
| v0.9.0 | 2026-08 | Analyzer v3.0 (8-Phase), Candidate/Verify 9/9, Knowledge Promotion, Workflow DSL, Pipeline Orchestrator, Event Bus, Memory Layer, Governed-ready |
| v0.8.0 | 2026-08 | Stage Contract + Validation + QA Sub-Agent, Interface 统一 |
| v0.7.0 | 2026-07 | 9-module PLAN Contract, Dispatcher Pattern, Knowledge Lifecycle v2.0, capabilities.yaml |
| v0.5-0.6 | 2026-06/07 | 职责边界, Capability Registry, DAG Scheduler, Context Protocol |

## 当前优先级（未完成项）

> 从「功能清单」转「问题驱动」。方向性修正：**project-suite 是 Protocol，不是 Engine**——不做 Runtime Engine、Convergence Engine、Scheduler Engine、强制 Stop。目标从「执行完整性」改为「协议完整性」：把 Protocol 边界定义严谨，不假装有强制能力（见 [host-capability.md](../runtime/contracts/host-capability.md)）。

### P0 — Protocol Integrity（协议完整性）

- [x] 行为评估收敛：统一词汇（三层工件：pressure-tests 定义 → results 运行 → ledger 判定），五段格式升级为六段（加 `repeatability`）

> 已完成：Protocol Contract 一致性（check-consistency.sh）、Host Capability Contract、Exit Criteria→Evidence→Convergence、description 去「产出/行为句」收口（discoverability 归 description、contract 归 skill.yaml produces）。
>
> 2026-09-18 补：<br>
> · `check-drift.sh` 三处假检查修正（见 G0）；<br>
> · `eval-contract.md` 增「两种 baseline（ablation）」+「新增机制的准入义务」——把「机制值不值得存在」与 ADR-005 A5 的「能不能验证」明确分开；<br>
> · generator / planner / architect / analyzer 的 description 各加一行负边界（`不用于：…`）。
>   **⚠️ 路由效果尚未验证**，对应压力测试 `cross-skill-routing.yaml` R8–R12，跑完才可写结论。

> **2026-09-18 · Verification Contract（消灭「幽灵 Verify 阶段」）**：<br>
> · **元原则**升格为 [SUITE_SPEC §0.1 Runtime Reachability](../SUITE_SPEC.md)：「任何声明存在的行为，都必须能沿 Host 的真实执行路径找到入口；仅有文件/配置/计数/静态 ✅ 都不算可执行」，逆命题（零运行时消费者的声明要删或给入口）同样成立。<br>
> · `workflow-protocol/SKILL.md` 定义 **Verify 不是 Stage**，而是由 Stage 加载的验证子流程；`verification.mode` 由此获得**第一个真实消费者**（此前 10/10 声明、零消费者、无 schema）。<br>
> · 8 个 SKILL.md 删掉误导性的 `Verify` 表行；planner 的 `Interview` 行折进 Discovery（两行都不在 `stages` 里）。<br>
> · `pipeline-orchestrator`：`direct-verify → none`（它没有 verifier.md，也不该有——编排器不验证业务产出）。<br>
> · **generator 的 mode 由 `direct-verify` 改为 `candidate-verify-accept`**——依据是它自己的 prompts（`Phase 1: Candidate Generation` + verifier 的 Accepted/Rejected 判定表），原声明与实现不符。<br>
> · 新增门禁：`check-consistency` 断言 **SKILL.md 表行集合 == `interface.stages`**；`check-conformance` **G19 Verification Reachability**；`check-e2e-smoke` **§6 沿 `interface.stages` 走查**。<br>
> · 行为级证据（含**负对照 ablation**）见 eval 仓 `benchmark/pressure-tests/verification-reachability.yaml`（VR1–VR3）——**设计态、尚未运行**。
>
> **2026-09-18 · 外部评审 13 条的处置（全部核实后执行）**：<br>
> · **③ analyzer stages 顺序**：`[discovery, execution, delivery, validation]` → `[discovery, execution, validation, delivery]`，
>   与 `workflow-library.yaml` 的 standard 流程对齐；**并补上缺口检查**——此前只查「SKILL.md 表行 == `interface.stages`」，
>   漏了「`stages` == workflow-library 指派值」，故 §analyzer 的错误**跨文件也不报**。<br>
> · **① Recommendation 链**：resolver 加 `recommendation` 分支 + 独立桶、schema 补 `context.recommendations` 与
>   `recommendationEntry`、`check-knowledge-pipeline` 与 `check-e2e-smoke` 各补**消费端**断言。
>   此前只测到 index（Producer 侧），recommendation 被静默塞进 `knowledge` 桶且无人报错。<br>
> · **④ gates.yaml 双权威**：删除 9 个 skill 的 `confidence: warn_below/block_below`——conf 三档唯一权威是
>   `rules.yaml` 的 `gate:`（**这本就是 ADR-003 的规定**，gates.yaml 里的那一段是回退）。<br>
> · **⑤ `auto_accept_threshold` → `suggest_accept_threshold`**：原名声称「自动标记为 accepted」，与
>   `knowledge-lifecycle.md`「Candidate 不是自动升级」直接冲突。<br>
> · **⑦ `VALID_TYPES` 手抄副本**：改为**运行时从 `artifact-types.yaml` 解析**（不引入生成器，少一处新鲜度断言）；
>   解析失败时**响亮失败**而非静默放行。<br>
> · **② Domain Model**：按方案 B 摘除——契约移除 `domain/` 条目、planner `interview.md` 移除 Domain-Aware Questioning
>   一节、analyzer 产出树同步、`domain-model.md` 归档到 `docs/archive/`。理由：**有 Contract、有 Consumer、没有 Producer**
>   （extractor-registry 里无 domain extractor），属 §0.1 要挡的形态。<br>
> · **⑩ 恒红存根归档**：`check-decay.sh` **与 `knowledge-query.sh`**（同为 DEPRECATED + 恒 `exit 1` + 无调用方）
>   移入 `docs/archive/`，3 处引用同步更新。留在 `shared/scripts/` 只会磨掉红灯的信号价值。<br>
> · **⑥ context-package 的「两个 Producer」**：核实后**不是双产出**——planner 只是**触发** resolver
>   （`delivery.md:8`「调用 knowledge-resolver.sh 生成」），故移除 planner 的 output 声明。
>   **连带抓出一个真缺口**：planner 的 prompts 读 `context-package.json` 却从未在 `inputs` 里声明——已补
>   （e2e §3 抓到的）。<br>
> · **② 已处置**：`context.components/api/artifacts` 三个桶**已从 schema 移除**——核实确认
>   **无任何 Producer**（resolver 0 次 push、planner 无填充指令）**且无任何 Consumer**（提示词只读
>   rules[]/knowledge[]/guidance[]/recommendations[]），判定为「设计未落地，不属于当前契约」，
>   对应的 `$defs`（artifactRef/componentRef/apiRef）一并移除。**恢复条件：Producer + Consumer + Verify
>   一次性闭环**——不为「让 schema 和注释一致」去补实现。
>
> · ~~仍待定：`context.components/api/artifacts` **无人填充**（resolver 里 0 次 push，planner 也无填充指令），
>   而 schema 注释声称「由 Planner 经 graph-query 填充」——需确认是设计未落地还是注释过时。

> **2026-09-18 · 外部评审第二批 4 条的处置（全部核实后执行）**：<br>
> · **P0 Domain 摘除收尾（方向与提案相反）**：`domain/vocabulary.yaml` 的 Consumer 实为 **4 处**
>   （architect V11 / generator V7 / reviewer V7 / planner `task-breakdown.md`×2），但**Producer 是存在的**——
>   Glossary Extractor（`extractor-registry.yaml`）→ `candidates/glossary.yaml` → `architecture/glossary.md`
>   （`indexed_by_compiler: true`）。真实项目该文件 573 行，含核心术语表 **与「产物 artifact」的 `naming` 前缀表**。
>   故**不删检查，改路径**：4 处重指 `architecture/glossary.md`，并去掉无 lifecycle 依据的「confirmed」措辞。<br>
>   → **教训（探针设计错 ≠ 数据不存在）**：上一轮判「无 Producer」时用的探针是 `grep -c "命名前缀\|naming"`，
>   命中 1 判为标题杂项。实际该表列名是中文「命名前缀」、值是前缀本身（`contractTracking` 等），
>   ∴ `grep naming` 必然命中 0。**断言写错方向，结论就整个反过来**——与 G5「全绿≠行为验证」同源。<br>
> · **连带修复 architect `verifier.md` 判定表编号漂移**：原文写 `V1-V8 全部通过` / `V5 失败(方案自相矛盾)` /
>   `V8 失败(domain 冲突)`，而该 skill 实有 **V1-V11**，且「方案自相矛盾」是 V8、「术语冲突」是 V11。
>   已按 `validation.md` 的 `On Failure` 列重写为一一对应。<br>
> · **P0 `knowledge-index.schema.json` 契约漂移**：`type.enum` 缺 `recommendation`（resolver 已真实产出该 type），
>   注释仍写「8 knowledge directories」（实为 9）。两处已改，并给 `check-knowledge-pipeline.sh` 补
>   **产物 vs 契约互校**断言：index 里出现的每个 type 必须在该 schema 的 enum 内（只取 enum 做集合比对，
>   不引 JSON Schema 引擎）。**变异测试**：摘掉 enum 里的 `recommendation` → 立即报红并点名该 type。<br>
>   → 此前这条漂移**完全静默**：产物已变、契约未跟、无任何断言覆盖。<br>
> · **P1 Recommendation 命名统一**：`recommendations.md`（旧「单文件」模型）残留 **8 处** → 统一为
>   `recommendations/`（权威模型是目录：`artifact-types.yaml` 的 location 用 `<建议-id>.md`、
>   `knowledge-directories.yaml` 的 path 用 `recommendations/`）。其中
>   **`generate-registry.mjs` 的 `CAPABILITY_TYPES` 模板**是关键一处——只改 `capabilities.yaml` 而不改它，
>   下次生成会把旧写法**写回去**。`skills.generated.yaml` 已重新生成。<br>
> · **P1 `exit_criteria.conditions` 删除**：见「已知缺口 G2」。<br>
> · **连带修复 `generate-registry.mjs --check` 的报告不实**：摘要**硬编码列出全部 4 个 registry 文件**，
>   而逐行结果可能只有 1 个漂移（`❌ capabilities.yaml — 漂移` 与 `✅ skill-catalog.yaml — 一致` 同屏出现，
>   两者却都被列为待修）。已改为只列真正漂移的文件并给出 `(n/total)`。**变异测试**：只改 1 个文件 →
>   摘要显示 `（1/4）` 且只列该文件。

> **评估证据与治理契约分离**：行为评估的证据/结论（mechanism-verification-ledger.md、六段补完进度、benchmark round）归 `project-suite-eval/`，project-suite 只根据评估结论修复 skill 能力，不存测试证据。契约见 [eval-contract.md](eval-contract.md)。

### P2 — Knowledge Consumption

- [ ] Context Resolver 跨项目
- [ ] Knowledge Decay
- [ ] Knowledge Score

### P3 — Knowledge Automation

- [ ] Instinct Registry

> 已完成：Complexity Gate 三路径、depth_profiles 统一、知识缺口入口、prompt 瘦身、Convergence 统一协议（Decision Protocol）。

## 已知缺口（2026-09-17 迭代暴露）

> 起因：releaser 的 CHANGELOG 落点漂移（声明写项目根目录 / 契约写 `reports/`）被人工评审发现，
> 而**全仓检查绿灯放行**。顺藤摸出下面这批——**共同形状是「声明与实现各走各的，且没有任何检查能发现」**。
> 已修的同类问题见 commit 记录（artifact-types 裸写路径、skill-ir 无漂移检测、`checks` 计数失真、
> `writes_knowledge` 口径不一致、`producer` 字段语义）。
>
> **收录口径（2026-09-20 修订）**：本条清单**同时收录未修与已修**——已修的保留在案并标 ✅ + 日期 + 判据，
> 因为「为什么当初判它该删/该留」比"结案"本身更有复用价值（例如 G1 是靠**删**而不是靠**补**关闭的）。
> 未修项仍以 🆕 / 无 ✅ 标记。

### G0 — 「假检查」只做了抽查，未系统性排查（P1）

2026-09-18 一天之内在 4 个脚本里撞上同一形态：**检查声称做了某事，代码其实没做，还打印 ✅**。

| 位置 | 假在哪 |
|------|--------|
| `check-drift.sh` Drift 1 | 注释写「produces vs actual output files」，代码只判断字段非空就 `✅ produces: […]` |
| `check-drift.sh` Drift 2 | `head -10 \| grep "description:"` 只取到 `description: >` 一行，关键词**永不可能命中** |
| `check-drift.sh` Drift 5 | 把 inputs+outputs 一起数了却断言 `N output(s) match produces` |
| `generate-skill-ir.sh` | 用 `grep -c "\| V"` 误把判定表行数当校验项数（4 个 skill 虚高） |
| `knowledge-compiler.sh` | `sed -n '1,15p'` 硬窗口：字段写在第 17/19/24 行 → 「补齐成功」与「拒绝生成 index」同时成立 |
| `check-artifacts.sh` §1 | 标为「Spec → Plan」，但**只读 PLAN 一个文件**——没有任何 spec 输入，等于拿 PLAN 和自己比 |
| `check-artifacts.sh` §3 | 纯 echo：输出 "verify tasks cover them" 却**没有任何比对** |
| `check-artifacts.sh` §4 | 路径 `$KNOWLEDGE_DIR/../runtime/...` 指到**项目根**的 runtime/ → 真实项目里该节**永不执行** |
| `check-approval-audit.sh` Check 1 | 注释写「Each skill execution has approval_log entries」，代码只判 `approval_count > 0`，**从不比较 skill_count**。实测 2 次执行 1 条记录照样 ✅ |
| `check-artifacts.sh` Summary | 行标签「Spec → Plan」，取值却是**全局** ISSUES（含 §2/§4/§5/§6） |

以上**均已修**。另修了一处**跨 7 个脚本的系统性隐患**：

```bash
var=$(grep -c X f 2>/dev/null || echo 0)     # ❌
```
`grep -c` 在「文件存在但零匹配」时**已打印 0 且 exit 1**，`|| echo 0` 再补一个 → 变量变成两行 `0\n0` →
后续 `[ "$var" -gt 0 ]` 报 integer expression 错误并**静默走 else 分支**。危害不止报错：
`check-artifacts.sh` §1 因此**在最该报警时保持沉默**；`generate-skill-ir.sh` 会把这个值**直接写进
`skill-ir.yaml` 的 `modes` 字段**，产出坏 YAML。正确写法：`var=$(grep -c X f || true); var=${var:-0}`。
（涉及 `check-approval-audit` / `check-artifacts` / `generate-skill-ir` / `show-events` / `collect-metrics` / `knowledge-scan`）

**仍未做的**：这些多半是**撞上的，不是查出来的**。已抽查 `check-e2e-smoke`（**干净**，§1–§5 都真比对）
与 `check-drift`（已修）。`check-reliability` / `check-conformance` / `check-consistency` / `check-decay` /
`check-io-connectivity`【1】【2】【3】仍在排查中，结论未出——**不要假定它们干净**。

### G0.1 — 全量排查结果（2026-09-18，逐一读码 + /tmp 合成夹具实跑）

**已修**：`check-drift`（3 处）· `check-approval-audit`（1 处 + 计数写法）· `check-artifacts`（4 处 + 参数守卫）·
`check-reliability`（5 处）· `grep -c … || echo 0` 双零写法（7 个脚本）

**未修**（按严重度）：

| 位置 | 假在哪 | severity |
|------|--------|----------|
| ~~`check-consistency.sh:79-87,94`~~ | ~~L1 的 5 字段比对在「两边都取不到值」时 空 = 空 → 判无 mismatch → ✅~~ **已修（2026-09-18）**：改为 `无法比对:A='…' B='…'`，缺失即报。变异测试：删掉 `produces` 行 → `无法比对:A='[Test]' B=''` 立即报红 | ~~中~~ 已闭 |
| ~~`check-consistency.sh:202-204`~~ | ~~L3.6 的 ✅ 完全继承 `check-io-connectivity.sh` 的退出码，而该脚本 1–3 节无正向断言~~ **已闭（2026-09-18）**：`check-io-connectivity.sh` 文件尾补**自检段**（断链/合法两个 fixture 双向证明判别力）。已变异验证：把 §1-3 的 `type:` 正则改坏 → 自检立刻报「故意构造的断链未被报出」→ exit 1。故「解析静默失效」这一路径已被覆盖，继承退出码不再是空壳 | ~~中~~ 已闭 |
| ~~`check-io-connectivity.sh:204`~~ | ~~终检 ✅ 宣称三项均已验证，但 1–3 节零输出~~ **已闭**：同上。另实测 §1-3 在真仓实际处理 **57** 行 interface type，非空转 | ~~中~~ 已闭 |
| `check-conformance.sh:45` | G2 用子串匹配（`grep -q "id:"`）冒充「字段完整」——注释、description 里出现即算通过 | 低 |
| `check-conformance.sh:215` | G15 查的是全局文件却放在 per-skill 循环里，同一句 ✅ 重复 10 次 | 低 |
| `check-conformance.sh:222-223` | G16 注释称「Skill Atlas 条目完整」，实际只查 skill 名在文件里出现过一次 | 低 |
| `check-conformance.sh:156-160` | G10 由 3 个字面量子串推导出普适结论「runtime-neutral」 | 低 |
| `check-consistency.sh:191-196` | L3.5 的 ✅ 在两侧集合都为空时也成立，且文案硬编码「（10/10）」 | 低 |
| `check-consistency.sh:224-230` | L4 由 3 个字面量黑名单推导「无技术栈硬编码」 | 低 |
| `check-io-connectivity.sh:91-97,69` | `type: state/request` 时断言静默跳过；`grep -E 'type: [a-z-]+'` 会漏掉带引号/大写 type（连「非法 type」都报不出） | 低 |
| `check-decay.sh:25` | 无条件 `exit 1`，纯打印存根；无调用方 | 低 |

**本轮（2026-09-18）已修**的审计项，均逐条实跑验证过（含「能否失败」双向验证）：

| 位置 | 修法 |
|------|------|
| `check-conformance.sh` G3 waiver | 原判定 `grep -q "waivers:" && grep -q "G3"` 近乎恒真。改为**必须有 `gate: G3` 条目**。实测 `# TODO(G3)` + `waivers: []` 不再获得豁免；真条目仍认 |
| `check-conformance.sh` G3 expires | 补 GNU `date -d` 回退；解析失败时明确判「无法确认」而非空值当 0（原来有效豁免一律报过期） |
| `check-conformance.sh` G5 | 从「grep 到一个 ✅」收紧为**同时含 ✅、❌ 与表格分隔行**（实测 10/10 skill 仍通过，未造误报） |
| `check-conformance.sh` G13/G14 | 加空集守卫：读不到 `stages` 时 **WARN「无法判定」**，不再是 `0/0` 的永真 PASS |
| `check-conformance.sh` **静默中止** | 5 处 `$(find\|grep …)` 补 `\|\| true`。实测：删掉一个 skill.yaml 的 `stages:` 行，改前**在 G12 后死掉、无 Summary、exit 1**（与「查出 warnings」不可区分）；改后跑到 Summary、G13/G14 正确 WARN、**exit 2 可区分** |
| `check-consistency.sh` L0 | 不再吞掉 `check-yaml.sh` 的「门禁未生效」提示；无 parser 时报 ⚠️ 而非「✅ 所有 .yaml 可解析」。用假 `ruby`/`python3` 实测两个分支 |
| `check-reliability.sh` 5 处 | confidence 空 vs 空判「稳定」→ 拆出「无法比较」；`md5` 缺失时两侧空串恒等 → 先探可用性 + 失败哨兵；`FAIL` 恒为 0 / `exit 2` 死分支 → 快照不可读时 `FAIL++`；死代码 `md5_a/md5_b` 删除；confidence 正则放宽空白（`JSON.stringify` 无空格时原来完全取不到值） |

> **正面结论**：`check-e2e-smoke.sh` 抽查**干净**；`check-consistency` 的 L1补（`generate-skill-ir.sh --check`）
> 与 L2（`generate-registry.mjs --check`）经查是**真实的逐字节比对**，不是空壳 ✅。

> **另一个必须记下的事实**：这些脚本的退出码**没有任何机器消费方**（无 CI、无 hook、无脚本调用它们）。
> 唯一的消费方是**人**——本会话里我多次拿「check-conformance PASSED」当证据。所以假 ✅ 的实际危害
> 不是「流水线漏检」，而是**让人相信了不成立的事**。修它们不是为 CI，是为不骗人。

### G0.2 — 变异测试：全套检查的盲区（2026-09-18）

方法：**破坏它声称能防的东西，看它到底会不会红**（比读代码可靠——我第一版探针写错了，
报出「5 个检查全红」的假结果，手工复跑才发现是探针的锅）。

| 变异 | 结果 |
|------|------|
| `SKILL.md` 的 `name:` 改成与目录不符 | ❌ **四个检查全绿放行** → 已补 L1 断言（见下） |
| `artifact-types` 的 `producer` 指向不存在的 skill | ❌ 无人报红 → **只记录不修**（该字段零消费者，同 G1） |
| `SKILL.md` 里打断一个同目录链接（`prompts/x.md` → `prompts/NOPE.md`） | ❌ 全绿放行 → 已修（见下） |
| `skill.yaml` 的 `produces` 含未知 capability | ✅ consistency + conformance |
| input 的 `type` 非法 | ✅ consistency + conformance + io-connectivity |
| `skill.yaml` 去掉 `boundary` | ✅ consistency + conformance |
| `stages` 指向不存在的 prompt | ✅ consistency + conformance |
| 删除 `skill-ir.yaml` | ✅ consistency + conformance |
| 提示词引用未声明目录 | ✅ consistency + conformance + io-connectivity |

**已修**：

- **`check-drift` Drift 3 的链接覆盖面**：原正则只匹配 `../` 开头的链接，同目录链接一个不查，
  却输出「**All** SKILL.md links resolve」。实测打断 `prompts/discovery.md` 四个检查全绿放行。
  放宽到全部相对 `.md` 链接后，**覆盖面从 35 个链接增至 97 个**（原来只查了 36%），现状仍 0 drift。
- **`check-consistency` L1 新增 `SKILL.md.name == 目录名` 断言**：`name` 正是 Host 注册 skill 用的标识，
  改名会让它以错误身份被路由，而其余声明完全自洽。现状 10/10 一致，变异后立刻报红。
- **闭环 fixture 补 `recommendations` 桶**：fixture 只建了 9 个 indexed 目录中的 8 个，
  于是 compiler 的 `emit_one "recommendations" …` **从未被闭环测试执行过**——该桶若写错
  （目录名/类型/优先级），测试照样全绿。已补目录 + 文件 + 断言，并验证：把该桶的目录参数改错后
  （I1 仍通过，因为它只看 emit_one 的首个参数）新断言能报红。

### G1 — 无消费者的声明字段（P1，本轮最核心）— ✅ 已关闭（2026-09-20）

| 字段 | 实证 | 现状 |
|------|------|------|
| ~~`artifact-types.yaml` 的 `location`~~ | `release.location` 曾长期指向项目根目录 `CHANGELOG.md`，与契约的 `reports/` 矛盾 | **已修**：现为 `.project-knowledge/reports/CHANGELOG.md + …/RELEASE-CHECKLIST.md`（[artifact-types.yaml:110](../runtime/artifacts/artifact-types.yaml#L110)）。原「无脚本解析、只能靠人工评审」的判断仍成立——**它不得不再犯，但也不需要为它建机器** |
| ~~`skill-interface.schema.yaml`~~ | **已归档到 [docs/archive/skill-interface.schema.yaml](archive/skill-interface.schema.yaml)**（2026-09-18）——无消费者，且不为「让 schema 有人读」而补消费者（那会变成第二套 interface authority） | 已处置 |
| ~~`context_contract`（10/10 声明，0 消费者）~~ | 见 G1.1(a) | **已删除**（2026-09-20） |

**原「要修的前置条件」的结论（2026-09-20 改写）**：当时设想的「新建 `shared/schemas/skill.schema.yaml`
声明顶层字段」**不再需要**——顶层字段里唯一无消费者的那个（`context_contract`）已按 §0.1 逆命题整体删除，
其余顶层字段（`triggers_*` / `depth_profiles` / `capabilities` / `stages`）都已有真实消费者
（`generate-registry.mjs` → registry，且 `stages` 现由 G21 校验）。
**为「让声明看起来被治理」而造 schema + `--check`，本身就是在加层——本例正是靠"删"而不是靠"补"关闭的。**

### G1.1 — 独立扫描新发现：`context_contract` 是死胡同 + `compatibility` 块 0/10 — ✅ 均已删除（2026-09-20）

> 来源：本轮在 roadmap 与两批外部提案**之外**做的一次独立扫描——逐个 `skill.yaml` 顶层字段 ×
> 「脚本消费 / 提示词提及」交叉统计。两条都属 G1 同一族：**声明齐全、语义自洽、零入口**。

**(a) `context_contract`（含 `must_read` / `neednt_read`）：声明 10/10，消费者 0 → 已整体删除**

- 其存在理由是「Context 裁剪（减少 context 膨胀）」（SUITE_SPEC §3.1 🔴 REQUIRED）。
- 实际链路：`skill.yaml` → `generate-registry.mjs`（`grabBlock` 抄进 `skills.generated.yaml`）→ **终止**。
  而读 `skills.generated.yaml` 的唯一地方是 `check-conformance.sh` **G7**，判定式为 `grep -qE "^  ${skill}:"`
  ——**只看 skill 键在不在**，从不读它下面的内容。
- **零提示词提及**：`must_read` / `should_read` / `neednt_read` 三个词在全仓只出现在
  `SUITE_SPEC.md` 自己的定义里。LLM 从不按它加载或跳过文件。
- **附带命名漂移**：SUITE_SPEC §3.1 写 `should_read`，而 **10/10 skill.yaml 实际用 `query`**。
  全仓 `should_read` 仅存在于 SUITE_SPEC 的定义处 —— 0/10 一致。

**(b) `compatibility:` 块：SUITE_SPEC §3.2 标 🟡 IMPORTANT 且写「**必须**声明」，实际 0/10 声明 → 已删除**

- 且 G1–G17 无任何一项覆盖它，所以「0 个 skill 遵守 MUST」这件事全仓绿灯、无人报。
- ⚠️ **同名冲突**要注意：`runtime/registry/compatibility.yaml` 是**另一个东西**（版本兼容矩阵，
  check-consistency 的 L3 在真实消费它）。改这条时不要误伤 L3。

**实际处置（2026-09-20 执行，非"待定"）**：

- (a) 按 §0.1 逆命题**整体删除**——10 份 `skill.yaml` 的 `context_contract:` 块 + SUITE_SPEC §3.1 字段定义
  + `generate-registry.mjs` 三处（`grabBlock` 注释 / 提取行 / emit 行）+ `rules.yaml` 的 `cross_skill.context_loading` **整块**
  + `compatibility.yaml:138` 的 `migration_guide` 措辞。**ADR-001 / ADR-003 里的相关条目直接删除**——
  残留的删除线+修订注会让两处 ADR 各自复述一遍同一段移除史（已由本节承载），属"同一事实两份权威"。
- **删除的关键判据不是"零消费者"（那只够降级为"待定"），而是它是同一事实的第二份权威**：
  `must_read` 与 `interface.inputs` 描述同一件事，而实测 **10/10 已漂移**——
  analyzer 的 `must_read: []` 对 7 项 inputs；refactorer 的 inputs 里根本没有 `context.json`；
  reviewer/generator/tester 把 `context.json` 只写在 must_read。**两份权威已经不一致了，留哪份都不是"补一补能用"。**
- (b) 删除 SUITE_SPEC §3.2 的 skill 级 `compatibility:` MUST 段，改为指向 `runtime/registry/compatibility.yaml`
  （ADR-003 早已判定「版本兼容约束 → compatibility.yaml 的 matrix」，SUITE_SPEC 与已 Accepted 的 ADR **直接冲突**）。
- **规则沉淀**：`runtime/config/rules.yaml` 的 `cross_skill.context_loading` 块**已整块删除**（原写「按
  context_contract 执行」是**假声明**——描述一个不存在的执行路径；连同 `priority: context-priority.yaml` 一并去除）。
  **不留墓碑**：Context 的加载/裁剪/合并**没有**机器执行契约，它是 Prompt/Host 的职责；把这条写进
  `rules.yaml`（一个每条目都带可消费字段的 Runtime 规则文件）本身就是又一次「把 Engine 当 Contract」。

**(c) 同一族的更重发现：`runtime/context/` 里一整套 Context Engine 规格，零消费者 — ✅ 已清场（2026-09-20）**

- **发现**：`runtime/context/` 下 6 个文件里，有 **4 个是一套「Context Engine」的规格**：
  - `context-priority.md/.yaml` —— sources 优先级栈（6 源 × override/append/ignore）、`fields` 三级
    （required/important/optional，每字段带 `affects`）、**程序化 `gate` 决策树**（`check_context_exists`
    / `check_required` / `check_important` / `try_extract_from_knowledge`）、`merge_rules`。
    其 .yaml 自称「从 .md 提取的**可执行**版本」。
  - `merge.md/.yaml` —— 跨源冲突合并（`operations` / `conflict_resolution`），自称
    「Machine Readable Spec」「Skill 加载时: `YAML.parse()` → 按 sources 顺序加载 → 按 conflict_resolution 裁决冲突」。
- **消费者审计（决定性证据）**：4 个文件全部**零机器消费者**——无脚本读取、无提示词提及、无 skill 引用；
  唯一的引用者是彼此的 .md/.yaml 孪生 + ADR-001 的 Related 列表。**一个自指的孤岛。**
  （本轮清场后连 ADR-001 的入链也去掉了：孤岛已无任何外部引用。）
- **定性（本轮采纳的判据）**：这不是「缺一个 Consumer」，而是**「它本来就不该成为 Runtime Contract」**。
  它描述的不是「一个产物长什么样」，而是「机器如何加载/校验/合并上下文」——
  属 **SUITE_SPEC §0.1 逆命题**要挡的形态：**把 Suite 从 Protocol 做成 Engine**。
  与 `context_contract` 是同一错误路线，且**更重**：后者只是一个字段块，前者是整套引擎规格。
- **处置（对 .md 与 .yaml 分别处理——这是本轮的精确化）**：
  - **`.yaml` 两份（`context-priority.yaml` / `merge.yaml`）→ 物理删除。**
    它们是**机器可解析/可直接执行**的规格（前者自称「从 .md 提取的**可执行**版本」、带程序化 `gate` 决策树；
    后者自称「Machine Readable Spec」「Skill 加载时: `YAML.parse()`」）。**留一份可执行规格在场，
    就仍是"半残 Contract"**——这正是本轮要根除的形态。删除后全仓不再存在任何 Context Engine 执行规格。
  - **`.md` 两份（`context-priority.md` / `merge.md`）→ 归档到 [docs/archive/](../docs/archive/)**，
    带 `⚠️ 已归档` 头注说明理由。它们是**散文设计史**（为什么当初考虑优先级栈与 gate 决策树），有保存价值，
    但**绝不能继续留在 `runtime/context/`**——那里看起来仍像 active protocol。
  - **不补 Consumer**——补一个就等于造 Host Context Loader，把 Suite 变成 Context Engine。
- **保留的边界（关键区分）**：`runtime/context/` 现只剩 **2 个活的 Protocol 文件**——
  `context.md`（定义 `context.json` 这一产物 + 生产者/消费者表）+ `context-resolution.md`
  （context.json 与代码不一致时的裁决链）。**判据是描述「产物及其 LLM 处置规则」= Protocol（留）；
  描述「机器要执行的操作」= Engine（走）。**
- **同步清理的引用**（避免留下"半残契约"——指向已删/已归档文件的引用会把"已废弃"重新装饰成"权威"）：
  - `rules.yaml` 的 `cross_skill.context_loading` **整块删除**（原 `priority: context-priority.yaml` 字段悬空指向 `runtime/context/`）；
  - `ADR-001`：Consequences 里「context 可裁剪（经 context_contract）」一条**删除**，Related 里 `context-priority.md` 链接**删除**
    （不保留删除线+修订注——移除史由本节单一承载）。**ADR-001 的 Knowledge First / context.json 核心决定不动。**
  - `ADR-003`：Skill Contract 图与 intrinsic 列表中的 `context_contract` **两处均删除**；
  - `SUITE_SPEC §3.1`：字段定义删除后，墓碑压缩成与同段 `priority` 一致的**一行**（此前写了三段，
    等于把本节的诊断复制成第二份权威）；
  - `check-yaml.sh` 的历史注记补一行说明（它**仍覆盖 docs/archive/ 的 .yaml**，故注记保留历史价值）；
  - 归档的 `.yaml` 用 `#` 注记而非 markdown `>`——**`check-yaml.sh` 扫描全仓 `*.yaml` 且不排除 archive**，
    用 `>` 会让文件不可解析（本轮实际踩到并修正）；
  - 删除的两份 `.yaml` 在 HEAD 中留有 blob，可 `git checkout HEAD -- fang-skills/project-suite/runtime/context/<file>` 取回。
- **清场验收标准（2026-09-20 定稿，已升格进 SUITE_SPEC §0.1）**：
  **Retired Contract may exist in history/archive, but MUST NOT be referenced by any executable path,
  active schema, active configuration, generated artifact, or Host execution instruction.**
  **为什么需要它**：单靠「零消费者」不够——那只证明**删了不会坏**，证明不了**它没在暗示自己仍然存在**。
  本轮按这条逐类复查，**关键词扫描已全绿的情况下仍揪出三处**：
  - `SUITE_SPEC §3.1` 的字段墓碑（**已删**；本节的记录即为其唯一归属）；
  - `shared/scripts/check-yaml.sh` 注释里仍写着 `context-priority.yaml` 文件名（**已改为「一份已删除的
    Context Engine 规格」**——注释属 executable 文件，按新标准同样不许出现退役名）；
  - **归档 `.md` 的正文仍是现在时执行语态**——头注写了「已归档」，正文却还在命令
    （"所有 Skill 统一按此栈加载上下文"、"缺失任一项 → 下游 skill BLOCK，拒绝执行"、gate 决策树、
    BLOCK/降级提示模板）。**已逐句改为历史语态**，并在正文顶部加「⛔ 以下为历史描述，无执行者」横幅。
- **方法论教训（写进 §0.1）**：清场验收必须做**两遍**——先按**精确关键词** grep 定位，
  再**逐条读命中处是否仍在描述当前行为**。**不要搜 `context`**：`runtime/context/` 的
  `context.md` / `context-resolution.md` 是**活的 Context Protocol**，与要清退的 Context **Engine** 是两回事。
  本轮我自己就在第一次扫描时漏了 `grep -E`，得到满屏假 ✅——与「假绿」同族。

### G1.2 — Registry 真实缺口：`orchestrate` 未在 stage-library 注册 — ✅ 已修 + 已加门禁（2026-09-20）

- **缺口**：`pipeline-orchestrator` 声明 `stages: [discovery, orchestrate, validation, delivery]`，
  而 `runtime/registry/stage-library.yaml` 只有 6 个 stage、**没有 `orchestrate`**——
  Skill 声明的 stage「合法却无库可依」。同时 `discovery`/`validation`/`delivery` 的 `used_by`
  都漏了该 skill。这是**独立扫描之外、由外部提案指出**的真实漂移（我自己那轮没扫到：我只查了
  "声明有无消费者"，没查"声明是否落在注册表内"——**两个方向的漏检**）。
- **修复**：stage-library 补 `orchestrate`（`stages:` + `contracts:` 两处）+ 三处 `used_by` 补 `orchestrator`。
  **未新建模板**——`prompts/orchestrate.md` 自己声明 `@template: execution`，故 `template:` 直接指向
  `stage-templates/execution.md`。**"补一个 orchestrate.md 更完整"正是要避免的加层。**
- **门禁 G21（`check-conformance.sh`）**：断言「每个 skill 声明的 stage ⊆ stage-library」+
  「每个 stage 都有 `contracts`」+ 退化保护（解析出 0 个 stage 即报错，不静默放行）。
  措辞是**通用形式**而非只堵 orchestrate 这一个洞——同样的代码量，堵一类。
- **变异测试（四例全红，非"假 ✅"）**：
  1. 把 `orchestrate` 从 `stages:` 摘掉 → 报 `pipeline-orchestrator 声明 stage=orchestrate，但 stage-library.yaml 未注册该 stage`
     （**精确复现修复前的真实缺口**）
  2. 只从 `contracts:` 摘掉 → 报 `stage=orchestrate 在 stages: 里注册，但 contracts: 里没有对应 I/O 契约`
  3. 改坏一个 stage 键缩进 → 报 4 个 skill 的 `discovery` 未注册
  4. 全部 stage 键缩进 +1 → 触发退化保护 `未解析出任何 stage —— 断言退化`
  四例均以 `cmp` 字节级还原。
- **顺带**：stage-library 头部「Host 据此验证合法性」这句声明此前**零消费者**；现补记静态消费者（G21），
  声明与事实一致。

### G2 — 派生计数类字段缺防护

`verification.checks` 已修（收紧为 `^\| V[0-9]+ \|`，并加了「有 verifier.md 却数出 0 → 告警」）。

- ~~`exit_criteria.conditions`~~ — **已删除（2026-09-18）**。实测它是 `execution.md` 里**所有** `^- ` 行的计数，
  不是 Exit 条件数——generator 报 **23**，而其 `## Exit` 真实只有 **4** 条（Phase 2 的 V1-V6、步骤子弹全被算进去）。
  且**全仓零 Consumer**（只有生成器自己写、自己读不到）。按「没有消费者的派生字段不值得维护」整字段移除；
  **不修计数**——要算准就得写 Markdown 解析器，正是 SUITE_SPEC §0.1 要挡的形态。

- `failure_conditions.modes` — **已核，非同类缺陷，保留**。源是 `skill.yaml` 的结构化列表
  （`failure_modes:` 下的 `condition:` 条目），不是散文；实测 10/10 skill 计数与源一致
  （3/4/3/5/3/3/3/3/3/4）。与 `exit_criteria` 的关键差别：**它不误导**。零 Consumer 是事实，
  但删掉会失去唯一的机器可读失败模式索引，而它不产生错误信心——故留观，不删。

### G3 — 检查脚本的长期红灯

- ~~`check-decay.sh`~~ — **已归档到 `docs/archive/`**（2026-09-18）
- `check-reliability.sh` — **不是缺陷，已定性（2026-09-20）**：它是**参数化工具**（需传入快照路径），
  无参数时 exit 1 是**预期行为**，不是红灯。**不需要**接进主 check 链，也**不需要**给参数——
  把它接进主链只会让"无参数调用"变成常态化的假失败。归档亦不必：它有真实调用场景（比对两次快照）。
  结论：**保持现状，本条从"要修"改为"已澄清"**。
- `complexity-gate.sh` / `command-guard.sh` — 同为**参数化工具**（`<需求描述>` / `<命令>`），
  无参数即打印 Usage + exit 1，属预期。**同上，不需要接链。**

- ✅ **`collect-metrics.sh` — 三个缺陷，一修两修一定性（2026-09-20）**

  **缺陷 1（已修）：目录缺失时静默 exit 1**

  - **现象**：对任何**没有 `.project-knowledge/runtime/`** 的项目运行 → exit 1，且 **stdout / stderr 全空**。
    它连自己第 136 行的 `echo "Telemetry report: ..."` 都没走到，**不在 `reports/` 留任何痕迹**。
  - **根因**（原 :78）：`manifest_count=$(find "$RUNTIME_DIR" -name "manifest.json" 2>/dev/null | wc -l | tr -d ' ')`
    ——`set -euo pipefail` 下，**两个抑制器合谋**：① `2>/dev/null` 吞掉 find 的报错；
    ② `pipefail` 让 find 的 exit 1 穿透管道；最终 `set -e` 静默终止脚本。
  - **修复**：加**前置 guard**——`[ ! -d "$RUNTIME_DIR" ]` 时打印明确消息（含解析到的 project-root + 用法）并 `exit 1`。
    **不把「没有数据」伪装成「0 次执行」**——那正是本项目一直在清理的假绿问题。

  **缺陷 2（已修，更严重）：heredoc 体内 `${if …}` 应为 `$(if …)`**

  - **现象**：**脚本从未成功产出过任何报告**——对任何项目都崩，错误 `bad substitution`。
    它是被缺陷 1 掩盖的：没有 runtime 目录时先死在缺陷 1，有目录时才走到缺陷 2。
  - **根因**（原 :144，报告模板 heredoc 体内）：把**命令替换**写成了参数展开
    `— ${if [ … ]; then … fi}` → `${…}` 不是合法参数展开语法。
  - **修复**：`${` → `$(`，`fi}` → `fi)`（一个字符的笔误）。
  - **验证**：三种置信区间分支实测全部正确渲染
    （91→`healthy` / 70→`needs attention` / 40→`critical`），且报告正文数值正确（Total executions / Skills used）。

  **缺陷 3（未修）：第 62 行缺 `|| true` 保护，非格式化 JSON 下静默 exit 1**

  - **现象**：state.json 为**紧凑格式**（`"skill":"x"` 无空格）时 exit 1 且无任何输出。
  - **根因**：`skills_used=$(grep -o '"skill": "[^"]*"' … | sed … | sort -u | tr … | sed …)`
    ——`grep -o` 零匹配 exit 1，`pipefail` 使整个管道非零，`set -e` 静默终止。
    **与缺陷 1 完全同族**；而紧随其上的第 46–49 行**恰好就是用 `|| true` 防这个**：
    `total_executions=$(grep -c … 2>/dev/null || true)`——第 62 行漏了。
  - **影响面（为何严重度低于缺陷 1/2）**：suite 自己写入的 state.json 是格式化 JSON
    （`runtime/state/state.md` 的示例为 `"skill": "project-planner"`，**带空格**），
    实测规范格式下 `exit=0`、报告正常。**只在被外部工具压缩过 / 手写紧凑 JSON 时才触发。**
  - **修复**：一行——照第 46–49 行的既有惯例补 `|| true`。
  - **本轮未修**：用户将 ② 的范围限定为「只加一个前置 guard」，缺陷 2 经确认后作为例外放行；
    缺陷 3 属同一位置的同族问题但**不阻塞正常路径**，不再自行扩大范围。**留待用户决定。**

### G4 — 存量知识库未迁移

- `afc-newcore-web-frontend` 的知识库仍缺 `constraint`（2 个文件）→ 编译器拒绝生成 `knowledge-index.json`，**知识链仍是断的**
- `afc-newcore-web-code` 的 8 个派生补写值**未落地**（按协议回滚了）——尤其 4 个 `lifecycle: confirmed`
  的 `rules/`（`generatedBy: manual`），派生值可能与团队实际约定不符，**需人工复核后才可写入**

### G5 — 机制仍未被判定

benchmark 第 11–13 轮全部是 **suite-only（无 native 臂）**，`mechanism-verification-ledger.md` 里
「Producer 契约字段」「frontmatter 读取（无行数硬窗口）」两项均标 `untested`。`pass` 需要
native-vs-suite delta + repeatability，缺 native 臂则永远判不了。

### G6 — 路径裸写的已知边界（不是缺陷，是断言的能力上限）

I2/4.4 只校验**带 `.project-knowledge/` 前缀**的写法。裸写目录名（`components/`）或裸文件名
（`CHANGELOG.md`）机器无法判断是知识产物还是项目文件——**只能靠人工评审**，已写进契约头的路径写法约定。
`skills/*/references/` 里仍有大量裸写（如 `development-flow.md` 的 `components/`），多为上下文内的相对引用，不必改。
