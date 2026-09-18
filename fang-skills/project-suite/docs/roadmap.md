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
> · **元原则**升格为 [SUITE_SPEC §0.1 Runtime Reachability](SUITE_SPEC.md)：「任何声明存在的行为，都必须能沿 Host 的真实执行路径找到入口；仅有文件/配置/计数/静态 ✅ 都不算可执行」，逆命题（零运行时消费者的声明要删或给入口）同样成立。<br>
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
> · **仍待定**：`context.components/api/artifacts` **无人填充**（resolver 里 0 次 push，planner 也无填充指令），
>   而 schema 注释声称「由 Planner 经 graph-query 填充」——需确认是设计未落地还是注释过时。

> **评估证据与治理契约分离**：行为评估的证据/结论（mechanism-verification-ledger.md、六段补完进度、benchmark round）归 `project-suite-eval/`，project-suite 只根据评估结论修复 skill 能力，不存测试证据。契约见 [eval-contract.md](eval-contract.md)。

### P2 — Knowledge Consumption

- [ ] Context Resolver 跨项目
- [ ] Knowledge Decay
- [ ] Knowledge Score

### P3 — Knowledge Automation

- [ ] Instinct Registry

> 已完成：Complexity Gate 三路径、depth_profiles 统一、知识缺口入口、prompt 瘦身、Convergence 统一协议（Decision Protocol）。

## 已知缺口（2026-09-17 迭代暴露，未修）

> 起因：releaser 的 CHANGELOG 落点漂移（声明写项目根目录 / 契约写 `reports/`）被人工评审发现，
> 而**全仓检查绿灯放行**。顺藤摸出下面这批——**共同形状是「声明与实现各走各的，且没有任何检查能发现」**。
> 已修的同类问题见 commit 记录（artifact-types 裸写路径、skill-ir 无漂移检测、`checks` 计数失真、
> `writes_knowledge` 口径不一致、`producer` 字段语义）。以下只记**未修**的。

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
| `check-consistency.sh:79-87,94` | L1 的 5 字段比对在「两边都取不到值」时 空 = 空 → 判无 mismatch → ✅（字段缺失或块状 YAML 时即触发） | 中 |
| `check-consistency.sh:202-204` | L3.6 的 ✅「I/O 语义连通」完全继承 `check-io-connectivity.sh` 的**退出码**，而该脚本 1–3 节没有任何正向断言 | 中 |
| `check-io-connectivity.sh:204` | 终检 ✅ 宣称三项均已验证，但 1–3 节零输出、无正向断言——通过 = `FAIL` 仍为 0 | 中 |
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

### G1 — 无消费者的声明字段（P1，本轮最核心）

两个「纯文档、零脚本解析」的声明，会静默漂移：

| 字段 | 实证 | 现状 |
|------|------|------|
| `artifact-types.yaml` 的 `location` | `release.location` 长期指向项目根目录 `CHANGELOG.md`，与契约的 `reports/` 矛盾，全仓绿灯 | 无脚本解析；只能靠人工评审 |
| `skill-interface.schema.yaml` 整体 | `check-conformance` / `check-drift` **都不引用它** → skill.yaml 从未被 schema 校验 | 纯文档 |

**未修原因**：为零消费者字段建机器不划算。本轮已给该 schema 加过一版声明又**撤回**——
把它声明到 `fields:`（`interface` 的子字段）是错的，它属于顶层 `context_contract:` 块。

**要修的前置条件**：若新建 `shared/schemas/skill.schema.yaml` 声明顶层字段
（`context_contract` / `triggers_cn` / `triggers_en` / `depth_profiles` / `capabilities` …），
**必须同时配 `--check`**。否则只是再造一个不会自我发现漂移的声明——正是本轮的成因。

### G2 — 派生计数类字段缺防护

`verification.checks` 已修（收紧为 `^\| V[0-9]+ \|`，并加了「有 verifier.md 却数出 0 → 告警」）。
**同类未核**：

- `exit_criteria.conditions` — 数 `execution.md` 的 `^- ` 行数
- `failure_conditions.modes` — 数 skill.yaml 的 `condition:` 行数

两者都是「源文件结构一变就失真」的代理指标。要修：核一遍真值，或同样加「源结构不符即告警」。

### G3 — 检查脚本的长期红灯

- ~~`check-decay.sh`~~ — **已归档到 `docs/archive/`**（2026-09-18）
- `check-reliability.sh` — 需要快照参数，无参数即 exit 1

要修：要么接进某个入口并给参数，要么明确标注废弃/移入 `docs/archive/`。**长期红灯会让整条检查链失去信号价值。**

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
