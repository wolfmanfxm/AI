# 机制验证台账（Mechanism Verification Ledger）

> 回答元问题：**「设计好的机制，有多少真正改变了 Agent 的行为？」**
>
> 核心方法：问每一个机制一句——**「没有这个机制，Agent 会漏做哪个动作？」**
> - 答得上（会漏「先读源码」「真跑测试」）→ 机制改变行为
> - 答不上（「对照 PLAN」「够用就好」LLM 本来就会做）→ 机制是装饰品，或降级为「纪律强制」

## 判定维度

| 维度 | 取值 | 含义 |
|------|------|------|
| 类型 | 声明 / 额外动作 / 判断 | 机制是「改了声明」还是「要求额外动作」还是「要求正确判断」 |
| RED 假设 | 强 / 弱 / 未测 | 无 skill 时，LLM 会漏做这个吗？ |
| 验证状态 | ✅ 生效 / 🟡 Specified（Host 解读，非强制） / ⚠️ 纪律强制 / ❌ 装饰品 / 未验证 | 经 benchmark 实证的结论 |

## 正式回归基准格式（每个机制应填的 6 段）

> 这是「回归基准」的标准结构。每个机制一行 Hypothesis，验证时填 baseline/suite/evidence/repeatability/pass_fail。
> 场景定义（`scenario`/`naive_failure`/`assertion`）见 [pressure-testing.md](pressure-testing.md)，判定结论只在本台账记录。

```yaml
# 机制：<名称>
hypothesis: <这个机制应该改变什么行为？无 skill 时 LLM 会漏做什么？>
native_baseline: <不加载 skill 跑 scenario，实际发生了什么？>
suite_behavior: <加载 skill 跑同样 scenario，实际发生了什么？>
evidence: <round 号 + 任务名 + 可复现的证据>
repeatability: <N/M>   # 同一 scenario 跑 M 次，naive 漏做 / suite 补做的行为 delta 复现了 N 次
pass_fail: pass | fail | decorate | untested
  # pass     = RED 成立（native 漏做，suite 做了）且 repeatability 达标
  # fail     = 机制没生效（native 和 suite 一样）
  # decorate = 判断型，RED 弱（LLM 通用能力），价值是纪律强制
  # untested = 还没跑 baseline
```

**关键**：`native_baseline` 和 `suite_behavior` 必须来自真实 benchmark（naive vs suite 对比），不能凭空填。没有 baseline 数据的机制，标 `untested`，不假装「已验证」。

> **`repeatability` 与 [cross-run-reliability.md](cross-run-reliability.md) 的区别**：cross-run 测「产出文件结构跨 run 是否稳定」（结构稳定性，看输出）；repeatability 测「naive→suite 的行为 delta 能否复现」（行为结论的可复现性，看机制是否每次都能拦住）。前者答「输出稳不稳」，后者答「机制稳不稳」。

## 核心规律（round8 修正，推翻 round7）

**「额外动作型 RED 强 vs 判断型 RED 弱」的二分法已过时**——round8 实测 14 个机制（判断型 6 + 格式型 6 + 执行型 2）全部 RED 弱 = 装饰品。

真正决定 RED 强弱的不是「动作 vs 判断」的类型，而是**「当前模型是否默认会做」**——这是模型相关的，随模型进化而变。

- 当前模型默认会做（装饰品）：Read-then-Edit、file:line 引用、全状态覆盖、组件复用、跑测试、读源码、对齐项目、暴露 Gaps、逐条对照 AC…
- round7 曾判 RED 强的「可执行」「先理解」也已沦为默认行为（round8 复测推翻）

---

## 各 Skill 机制台账

> ⚠️ **证据诚实标注（round8 已补测 8 个）**：round8 补测了 6 个格式型额外动作型（组件复用、增量修改、完整性、精确引用、可操作、AC 对照）+ 2 个执行型（可执行、先理解），**全部 RED 弱 = decorate**（naive 没 skill 也做对），已降级为 ❌。这推翻了 round7 的「额外动作型 RED 强」分类——「Read-then-Edit」「file:line 引用」「全状态覆盖」「跑测试」「读源码」都已是当前模型的默认行为。剩余未补测：Evidence Score、先候选、决策可追溯、AC 驱动（大概率也 decorate）。

### project-analyzer（6 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| Evidence Score 溯源（每条 Claim 附 file:line） | 额外动作 | 强 | ✅ 生效 | 基准：suite 量化证据密度（198 个 UsingGet 等），native 定性 |
| 先候选再验证（candidate-verify-accept） | 额外动作 | 强 | ✅ 生效 | round5：candidates/accepted/rejected 区分明确 |
| 增量分析（缺领域只跑相关 Extractor） | 额外动作 | 强 | ✅ 生效 | round5 N5-INC：5 个相关 Extractor，非全量 10 |
| 知识缺口入口（新鲜知识库跳过） | 判断 | 弱 | ⚠️ 未单独测 | round3/4 验证过「跳过 vs 不跳过」，但粒度 vs 增量分析重叠 |
| 首扫建立完整骨架（交付契约门禁） | 额外动作 | 强 | ⚠️ untested（2026-09-30 补） | 两真实项目 1/14、12/14 目录却都声明 `completed`；门禁回放 exit 1 / 合规 fixture exit 0，**无 agent 臂**。详见「回归基准记录」 |
| 项目级 CLAUDE.md 入口（`check-claude-md.sh`） | 额外动作 | 强 | ⚠️ untested（2026-10-08 恢复） | 畅行首扫后 `.claude/` 为空、汽金有入口——**同一套 skill 差一个 agent 入口**；门禁 9 臂实测有判别力，**无 agent 臂**。详见「回归基准记录」 |

### project-planner（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| Contract over Todo（9 模块契约） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 输出 todo list，suite 输出 9 模块契约 |
| 放置决议 target（module/domain/placement） | 额外动作 | 强 | ✅ 生效 | round6 M1：落点 customerManage（纠正 round5 的 baseData 错误） |
| Knowledge First（先扫描可复用资产） | 判断 | 弱 | ⚠️ 过程质量 | 结构化 REUSE/EXTEND/CREATE 裁决 vs naive ad-hoc |
| Confidence 透明（<40 拒绝产出） | 判断 | 弱 | ✅ 生效 | round5 P3：naive 硬编，suite 暴露 Gaps |
| 事实/决策分域 + 高影响不降级（interview） | 判断 | ✅ 强（round17/18/19） | ✅ pass（round19 n=2） | round17/18：naive 把「短信验证」判为本期不做，suite 停 CHECKPOINT；**round19 n=2 同向复现**：suite 2/2 停 CHECKPOINT（confidence 65%/63%），naive 2/2 自行决定「不做」并继续实现（rep2 还预留验证字段位）。L2 `Skill 调用: 成功（project-planner）` 2/2。场景 `project-planner.yaml` P6 |

### project-architect（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 决策可追溯（对比矩阵 ≥2×3） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 单方案，suite 对比矩阵 |
| 现状核实先行（已实现不再设计） | 额外动作 | 强 | ✅ 生效 | round7：naive 凭空设计，suite 先 Code Audit 发现已实现→复用 |
| 上下文驱动（选型对齐项目约束） | 判断 | 弱 | ❌ 装饰品 | round10：naive 也选 SchemaTable+PageTable 并否决虚拟滚动/SSR（LLM 通用能力覆盖） |
| 够用就好（不过度设计） | 判断 | 弱 | ❌ 装饰品 | round7：naive 也够用就好，RED 不成立 |

### project-generator（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 使用项目组件（Reuse Ladder） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也用 PageTable/SchemaTable（RED 弱） |
| 增量修改（Read 再 Edit 不 overwrite） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也 Read-then-Edit（RED 弱，现已是模型默认行为） |
| 完整性（loading/empty/error 全状态） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也全三态覆盖（RED 弱） |
| 遵循项目模式（不凭框架记忆） | 判断 | 弱 | 🟡 一致性放大器 | round10+复验：naive 复制最近模块（ad-hoc），suite 系统化遵循项目约定；项目用 any 是事实非 skill 缺陷——value=一致性非质量 |

### project-tester（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 可执行（生成后尝试运行） | 执行型 | 强 | ❌ 装饰品 | round8 复测：naive 也主动跑测试（21 passed，借 node_modules workaround），RED 弱 |
| 先理解再测试（读源码理解边界） | 执行型 | 强 | ❌ 装饰品 | round8 复测：naive 也读源码、抓 0 不对称 bug（RED 弱） |
| AC 驱动（每条 AC 至少一个用例） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 只测 happy path |
| 项目约定优先（自动检测框架） | 判断 | 弱 | ❌ 装饰品 | round10：naive 也检测 vitest + .test.ts 命名（LLM 通用能力覆盖） |
| 失败分型 + 断言目标行为（RED 证据 ≠ 潜在 Bug） | 判断 | 弱（round17/18/19） | ❌ 装饰品 | round17/18：naive 在 L1 与 L2 都写目标断言、跑出 RED、不改源码、定位根因；suite 的 L2 增量仍只有 `[RED 证据]` 标签与 V1–V6。**round19 n=2 同结论**：naive 1 条 AC 用例 vs suite 3–4 条 RED + 边界，两边都 RED、都定位 `amount.ts:51/63`、都不改源码。L2 `Skill 调用: 成功（project-tester）` 2/2 |

### project-reviewer（5 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 精确引用（每个发现 file:line） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也逐条 file:line，甚至挖得更细（RED 弱） |
| 可操作（每个问题附修复建议） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也给「位置/改什么/为什么」可执行修复（RED 弱） |
| 分级明确（五级符号 + 五轴） | 额外动作 | 中 | 🟡 部分生效 | round7 P4：naive 模糊三档，suite 精确五级+五轴 |
| AC 对照（逐条验证） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也逐条对照 AC + file:line（RED 弱） |
| 放置正确（V7 对照 target） | 判断 | 弱 | ⚠️ 纪律强制 | round7 V7：naive 也发现错位（LLM 通用），价值是「强制每次对照」降漏报率 |
| 风险触发的独立盲扫（先盲扫再对照） | 额外动作 | 召回强 / 精确强（round19） | ✅ pass（触发 4/4；v2 0-BLOCKER 触发 2/2；Agent 派生 6/6 post-fix） | round18：0 BLOCKER + one-way 仍触发。round19：L2 触发 4/4、Agent 派生 4/4；v1 clean 夹具被 8/8 运行判为语义回归，v2 改为来源白名单并补齐 contractAudit 后 4/4 运行 0 BLOCKER，suite 2/2 由 one-way 触发 + Agent 派生，naive 2/2（bare）0 BLOCKER、无 QA。详见 [round19/analysis.md](benchmark/results/round19/analysis.md)。场景 `project-reviewer.yaml` P5 |

---

## 跨 Skill 机制

| 机制 | 类型 | 验证状态 | 证据 |
|------|------|---------|------|
| context_contract 语义化（query 替代 .md） | 声明 | ✅ 生效（修复后） | round5 #1「改声明没消费」→ 修复消费端 → round6 复验 |
| convergence 统一协议 | 声明（Decision Protocol） | 🟡 Specified（Host 解读，非强制） | round6 M1b：产出 sufficient→handoff；「handoff 真交接」靠 Host 解读，非 Suite 强制 |
| knowledge-list → context-package | 声明 | ✅ 生效 | 静态收口 + benchmark 复验 |
| Reuse Check primitive | 额外动作 | ✅ 生效 | round5：结构化 REUSE/EXTEND/CREATE 裁决 |
| 跨 Skill 路由准确（措辞 → 正确 skill） | 声明 | 🟡 部分验证（suite-only） | round11：R1–R7 实测 top1 命中 **5/6**（可路由项）；另发现 2 处缺陷（R6 orchestrator 未装载→无匹配；R7 changelog 误落 documenter）。**无 native 臂，RED 仍未判** |
| **Fresh Context**（跨 Skill /clear + state-only 传递） | 声明 / 成本行为 | ⚠️ 未验证（G1 欠账） | orchestration「每个 Skill 独立 /clear，只读 state/artifact」是核心编排，但**从未被 mechanism 级 ablation 过**。属 eval-contract 记的「Resolver/Registry/Gate/Fresh Context 机制级对象零条 ablation」——见下方六段 |
| 敏感面路由下限（complexity-gate → 至少 Standard） | 声明 + 判断 | 弱（round17/18/19） | ❌ 装饰品 / 静态 | round17/18：naive 两次都判 Standard 并要求安全审查；suite 增量是显式 `风险: HIGH` 与固定调度。**round19 2/2** 同结论；且 `complexity-gate.sh:96` 在 macOS bash 3.2 必崩（`$is_simple` 后全角逗号 + `set -u`），两次均回落 LLM rubric。**无 L2 入口**（pipeline-orchestrator 不是可加载 Skill），只能 L1。场景 `cross-skill-routing.yaml` R13 |
| Delivery Evidence · Safety Invariant + Proof | 额外动作 | 弱（round19 中性 2/2） | ❌ 装饰品 | round18：naive 也会跑可见证明；round19 合成迁移夹具（中性 prompt，2+2）：suite 与 naive 都执行 before FAIL→after PASS、都列出未证明项。suite 增量只剩结构化 `UNPROVEN` 字段与「不计 PASS」的格式纪律。场景 `project-releaser.yaml` P1；证据范围 `synthetic / production_validation: unavailable / production_rollback: false` |

> ⚠️ **2026-09-17 追加（已跑 suite 侧，RED 仍未判）**：verifier V2 追加证据要求 ——
> REUSE 裁决必须附 `命中` + `依据`（无证据 = V2 未通过），并明确「V2 = REUSE 且证据成立 →
> **零改动**是合法产出」。场景见 `benchmark/pressure-tests/project-generator.yaml` **P5**。
> **round11 G1 实测生效**：裁决带 6 条来源（catalog.md / patterns/upload.md / decisions.md D31 /
> index.md / graph.json 命中情况 / grep 27 消费方），**改动 0 文件**（git 独立核对属实），
> 且 agent 逐字引用了新条款作为「0 改动是规定产出」的依据。Reuse Check primitive 本身状态（✅ round5）不变。

---

## 统计

| 判定 | 数量 | 说明 |
|------|------|------|
| ✅ 生效（RED 强） | 9 | 仅剩「增量分析」「Contract」「放置决议」有实测证据，其余 4 个仍理论分类待 Batch3；**round19 新增 2 条**：事实/决策分域（n=2，suite 2/2 vs naive 2/2）、风险触发独立盲扫（触发 4/4、v2 0-BLOCKER 2/2、Agent 派生 6/6） |
| 🟡 初步通过（round17/18/19） | 0 | 无（Delivery 经中性 2+2 复测降为装饰品） |
| 🟡 部分/声明生效 | 2 | 分级明确（部分）、convergence（Specified，Host 解读） |
| 🟡 一致性放大器 | 1 | 遵循项目模式——系统化遵循项目约定（value=一致性非质量，round10 实证） |
| ⚠️ 纪律强制（RED 弱） | 1 | 放置正确（强制每次对照，降漏报率） |
| ❌ 装饰品 | 17 | round8+10 的 14 个 + round17/18/19 的 3 个（失败分型、敏感面路由下限、Delivery Safety Invariant + Proof——naive 在公平 prompt 下也做对） |
| 未验证 | 3 | ① 跨 Skill 路由准确（仅有静态证据）② 交付契约完成度门禁（2026-09-30：机械可核但**无 agent 臂**；2026-10-08 复测：畅行回填后首个真实 GREEN 臂，仍无受控过程）③ 项目级 CLAUDE.md 入口（2026-10-08 恢复的一条被删除规格：机械可核、无 agent 臂，且**幂等性无机械证明**）——均见「回归基准记录」 |

## 结论

**round8 的实证给出了终极结论：实测 14 个机制（round10 判断型 6 + round8 格式型 6 + round8 执行型 2）全部 RED 弱 = 装饰品——naive 没 skill 也全部做对，包括 round7 曾判为「唯一强 GREEN」的「可执行」（naive 现在也会主动跑测试甚至坚持跑通）和「先理解」（naive 也会读源码抓边界 bug）。round7 的「额外动作型 vs 判断型」二分法彻底过时，连「执行型」也不再是模型不会做的动作。suite 对当前模型没有「能力增强」，价值只剩「过程质量」（结构化、可追溯、一致性、强制对照降漏报率）。剩余 7 个 ✅ 里，只有 3 个有实测证据（增量分析/Contract/放置决议），且都可能是历史模型的产物，需按当前模型复测。**

这回答了元问题：**不是所有「设计好的机制」都改变行为——round8 实证 14/14 机制装饰品。机制是否改变行为是「模型相关的」，不是机制的内在属性；suite 的价值 = 过程质量（结构化/可追溯/一致性），不是能力增强。声明型必须验证消费端否则「改了没生效」。**

---

## 回归基准记录（已实测机制，五段格式样板）

> 以下机制已在 round5/6/7 跑过 naive vs suite baseline，按五段格式固化。**这是回归基准的样板**——后续新机制、或改动的机制，都按这个格式验证。

### 机制：先理解再测试（tester 原则3）

- **Hypothesis**：无 skill 时 LLM 凭函数名猜行为，漏掉真实边界（单位/返回类型/异常）
- **Native baseline**：凭 `parseAmount` 函数名猜「解析金额为元」，发明不存在的 options，漏掉「分单位/NaN/thousand 字符串」三个真实边界
- **Suite behavior**：读源码后覆盖 NaN、分单位、thousand 字符串全部边界
- **Evidence**：round7 N7-PT-tester-P3（native 猜错 + suite 全对）
- **Repeatability**：round8 复测推翻——naive 也读源码抓边界（`0→''` 不对称 bug）
- **Pass/Fail**：❌ decorate（round8 复测：RED 不成立，naive 也读源码；round7 结论是旧模型产物）

### 机制：可执行（tester 原则4）

- **Hypothesis**：无 skill 时 LLM 写完测试不实际运行就声称通过
- **Native baseline**：写完测试，未运行（「写完即可」自然行为）
- **Suite behavior**：`npx vitest run` 实际运行，8 passed
- **Evidence**：round7 N7-PT-tester-P4
- **Repeatability**：round8 复测推翻——naive 也主动跑测试（21 passed，借 workaround）
- **Pass/Fail**：❌ decorate（round8 复测：RED 不成立，naive 也跑测试；round7 结论是旧模型产物）

### 机制：现状核实先行（architect 原则3）

- **Hypothesis**：无 skill 时 LLM 不核实现状，为已实现模块凭空设计
- **Native baseline**：把「客户列表」当全新功能设计（不知道 customerCompany/customerIndividual 已存在）
- **Suite behavior**：先 Code Audit 发现已实现 → 标记 [已实现] → 复用
- **Evidence**：round7 N7-PT-architect-P4（native 凭空设计 vs suite 先核实）
- **Pass/Fail**：⚠️ 待复测（round7 结论；round8 的 14/14 decorate pattern 提示可能也装饰品，但未直接重测）

### 机制：够用就好（architect 原则4）

- **Hypothesis**：无 skill 时 LLM 会过度设计（预留微服务/MQ/多租户）
- **Native baseline**：也「够用就好」了（明确不加微服务/MQ/多租户）
- **Suite behavior**：也够用就好，无差异
- **Evidence**：round7 N7-PT-architect-P4（naive 与 suite 都不过度设计）
- **Pass/Fail**：❌ decorate（RED 不成立，LLM 通用能力，装饰品）

### 机制：放置正确（reviewer 原则5 / V7）

- **Hypothesis**：无 skill 时 LLM 不主动对照 Plan target 检查落点
- **Native baseline**：主动读 PLAN 也发现了落点错位（11 次 tool_use）
- **Suite behavior**：同样发现，但多了 V6 Domain Drift 联动 + BLOCKER 分级
- **Evidence**：round7 V7 两轮（有/无落点线索，naive 都发现了）
- **Pass/Fail**：⚠️ decorate（RED 弱，LLM 通用能力，价值是「强制每次对照」降漏报率）

### 机制：遵循项目模式（generator 原则1）

- **Hypothesis**：无 skill 时 LLM 凭框架通用知识裸写 axios/fetch + 通用分页参数，忽略项目 request 封装与命名约定
- **Native baseline**（round10 + 复验）：naive 探索源码、复制最近已有模块（templateManage.ts / dealerBrandCodeConf.ts）→ 正确用 request 封装 + `pageIndex`/`pageSize`，但「复制最近模块」是 ad-hoc（新增接口照抄旧模块的 `any` 写法）
- **Suite behavior**：suite 读 knowledge 后**系统化**遵循项目约定——request 封装、分页命名、返回类型，无论项目用 typed 还是 any，都忠实跟随 KB 对项目现状的描述
- **Evidence**：round10 N10-G1-P4 + round10b（复验：向 KB 注入「类型安全约定」后 suite 立即转向 typed，证明 suite 忠实跟随 KB 的任何内容）
- **Repeatability**：2/2 复现「suite 忠实跟随 knowledge」；复验进一步证明机制 = 一致性放大器（跟随 KB 描述，不论内容好坏）
- **Pass/Fail**：🟡 **一致性放大器**（非 decorate，也非质量放大器）：RED 弱（naive 也大致遵循），但机制价值 = 把 naive 的「复制最近模块」升级为「系统化遵循项目约定」。价值是**与项目一致**，不是**代码质量**

> **澄清**（round10 复盘）：`any` 是**本项目代码的真实现状**（analyzer 准确提取的 96.2%），不是 skill 要「修复」的。通用 suite 的职责是忠实描述并遵循项目约定，不施加「typed 优于 any」这类项目特定价值判断——那属于项目团队决策，不属于 skill 通用规则。此前把「类型安全」误当 skill 修复点，已撤回。

### 机制：上下文驱动（architect 原则2）

- **Hypothesis**：无 skill 时 LLM 追银弹方案（虚拟滚动/SSR/微前端/服务端缓存），选型脱离项目约束
- **Native baseline**：naive 探索 4 文件（PageTable/SchemaTable/SchemaSearch/creditApprove）→ 正确选 SchemaTable + PageTable 服务端分页，明确否决虚拟滚动/SSR/微前端/缓存/ag-grid/vxe-table
- **Suite behavior**：suite 探索 6 文件（+ creditExtend/approve + MpTable）→ 同样选 SchemaTable + PageTable，额外排除 MpTable（核心平台专用）+ 发现 rowcount vs total 陷阱
- **Evidence**：round10 N10-architect-P4
- **Repeatability**：1/1；与 round7「naive 也对齐了」一致
- **Pass/Fail**：❌ decorate（RED 弱，naive 也对齐了；价值仅「更系统的现状核实」，与「现状核实先行」机制重叠）

### 机制：项目约定优先（tester 原则1）

- **Hypothesis**：无 skill 时 LLM 不知道项目测试框架，用错框架（jest/mocha）或错误命名/目录
- **Native baseline**：naive 读 package.json 检测 vitest + 参考 crypto/__tests__ 已有测试 → `describe/expect/it from 'vitest'` + `.test.ts` 命名 + 覆盖 8 导出的边界（null/undefined/空串/未来/过去/长期/非法日期），手动核验 Date 边界
- **Suite behavior**：suite 同样检测 vitest + `.test.ts` + 覆盖 10 导出边界，额外区分权威 `__tests__/` vs 非权威 phone.test.ts（诊断工具非单测）
- **Evidence**：round10 N10-tester-P1
- **Repeatability**：1/1（与「与 generator 遵循项目模式同类」的预期一致）
- **Pass/Fail**：❌ decorate（RED 弱，naive 也检测到 vitest + 正确命名；价值仅「系统化读约定」非「从无到有」）

### 机制：知识缺口入口（analyzer 何时触发）

- **Hypothesis**：无 skill 时 LLM 重跑全量 10-Extractor 分析，不识别已有知识库（浪费 token）
- **Native baseline**：naive 跳过全量重扫，但从源码独立复现验证（17 次读取 package.json/config/源码样本），抓到 KB 一处 drift（max-old-space-size 4096→8192）
- **Suite behavior**：suite 跳过全量重扫，直接复用 KB（9 次读取 KB 文件），未抓到 drift
- **Evidence**：round10 N10-analyzer-P3
- **Repeatability**：1/1
- **Pass/Fail**：❌ decorate（RED 弱，naive 也跳过重扫）；⚠️ 优化点：skill「skip→Reuse」是盲信复用漏 drift，naive「skip+从源码复现」能抓 drift——建议加「跳过全量但仍抽查源码验证 KB 未漂移」中间路径

### 机制：Knowledge First（planner 原则2）

- **Hypothesis**：无 skill 时 LLM 忽略已有资产，把已存在的东西又规划一遍
- **Native baseline**：naive 扫 6 份 KB + 6 份源码，全程 REUSE/EXTEND/CREATE，发现「用户管理已存在」+ 僵尸组件 RoleSelector（0 引用）
- **Suite behavior**：suite 扫 10 份 KB + Code Audit，REUSE/EXTEND/CREATE，产出完整 9 模块 Contract
- **Evidence**：round10 N10-planner-P2
- **Repeatability**：1/1
- **Pass/Fail**：❌ decorate（RED 弱，naive 也扫描复用；价值仅「结构化 REUSE/EXTEND/CREATE 格式」，行为本身 LLM 通用）

### 机制：Confidence 透明（planner 原则4）

- **Hypothesis**：无 skill 时 LLM 硬编计划（信息不足也产出看似完整的 PLAN）
- **Native baseline**：naive 主动暴露 7 个 Gaps + confidence 25 + 明确「没有硬编」
- **Suite behavior**：suite 同样 7 Gaps + confidence 25 + 拒绝完整 PLAN（Goal+Scope+Gap List 格式 + 置信度公式）
- **Evidence**：round10 N10-planner-P3
- **Repeatability**：1/1；与 round5「naive 硬编」矛盾——效应不稳定
- **Pass/Fail**：❌ decorate（RED 弱，naive 也暴露 Gaps；价值仅「Goal+Scope+Gap List 固定格式 + 置信度公式」非「从无到有」）

### 机制：Producer 契约字段（`constraint` / `statement`）

- **Hypothesis**：无修复时，analyzer 产出 `patterns/` `components/` `api/` `decisions/` 时不写契约要求的
  frontmatter 字段（`statement` / `constraint`）——因为**权威字段表根本没说**，产出者按表走。
- **Native baseline**：未跑（本轮无 native 臂）。但有**跑前基线**：`statement` 合规 **0/23**（patterns 0/14、
  components 0/2、api 0/3…… 见下）。
- **Suite behavior**：round12 A1 实跑（增量分析 quotaManage 模块，**prompt 未提这两个字段**）——
  新建文件 `patterns 3/3`、`components 1/1`、`api 1/1` 含 `statement`；新建 `decisions 3/3` 含 `constraint`；
  **新建 8/8 合规**，且值有实质（可注入摘要 / 「必须…禁止…」硬约束），非为过检的空壳。
- **Evidence**：round12 A1（独立复核：用跑前备份做 diff，新/旧文件分开统计，**不采信 agent 自报**）；
  round12 C1（契约驱动编译器：真实项目 I1 通过）。详见 `results/round12/analysis.md`。
  **round13 A1（存量补齐）**：同一 prompt、同一基线，唯一变量是 knowledge-builder 新增的 Action 6——
  实测 **27 个既有文件被补写**（patterns 14 / decisions 4 / rules 4 / components 2 / api 3），
  **「只补不覆盖」零违规**（既有 frontmatter 键丢失/被改 = 0），补写值有实质（非空壳）。
  独立复核同样用跑前备份 diff，不采信自报。详见 `results/round13/analysis.md`。
- **Repeatability**：2/2（round12 生成侧 1 次 + round13 补齐侧 1 次；**均为 suite-side，无 native 臂**）
- **Pass/Fail**：untested —— 修复后行为**确实改变**（新建 0/23 → 8/8；存量 0/27 → 27/27），
  但按台账定义 `pass` 需 native vs suite 的 delta、且需 repeatability 达标；两项均不满足。**不冒充已判定。**

### 机制：frontmatter 读取（无行数硬窗口）

- **Hypothesis**：Compiler 读契约字段时不应依赖「前 N 行」的硬窗口——frontmatter 没有行数上限。
- **Native baseline**：未跑。但有**修前实证**：round13 C1 中补齐的 `constraint:` 落在第 17/19/24 行，
  旧实现 `sed -n '1,15p'` 读不到 → **「补齐成功」与「拒绝生成 index」同时成立**，链路依旧断着而两边日志都正常。
- **Suite behavior**：改用 `fm_field()`（按 frontmatter 块解析，首个 `---` 到闭合 `---`）后，
  编译器**首次**在该项目产出 `knowledge-index.json`（4,953 字节 / 8 个能力桶）。
- **Evidence**：round13 C1；回归锁 `check-knowledge-pipeline.sh` 5c（字段位于第 19 行仍须被读到，
  换回硬窗口即 FAIL——已双向验证）。
- **Repeatability**：1/1
- **Pass/Fail**：untested（同上：无 native 臂）

> ⚠️ **本轮最值得记的教训**：`constraint` 断链（round11）与硬窗口（round13）是**同一类问题的两个层次**——
> 前者「没人写」，后者「写了但读不到」。两者的共同点是**静态检查全绿**（fixture 的 frontmatter 很短、
> 字段都在前 15 行内），只有**端到端连起来跑**才暴露。

### 机制：跨 Skill 路由准确（suite 级）

- **Hypothesis**：无 suite 时，用户措辞会落到错误的 skill——「改」类超宽动词（generator 的
  「修改/调整/改」）会吃掉本属 reviewer/architect/planner 的诉求，用户要的是「先出结论/先出计划」，
  拿到的却是直接动代码。
- **Native baseline**：未跑（需按 `benchmark/pressure-tests/cross-skill-routing.yaml` 的 R1–R7
  真实发 prompt，观察落到哪个 skill）
- **Suite behavior**：未跑
- **Evidence**：静态——trigger-eval 新增「CN 跨 skill 子串包含」「CN↔EN 交叉」两条检查，实测
  3 组包含（发布⊂从分析到发布、开发⊂自动化开发、开发⊂开发计划）+ 1 组交叉（change ⊂ changelog）。
  这 4 组是**精确比对看不见**的冲突：旧 trigger-eval 报 `overlaps = 0` 是构造使然，不是健康证明。
- **Repeatability**：未测
- **Pass/Fail**：untested —— 静态证据只证明「声明层存在冲突」，不证明「行为层真的路由错」；
  没有 baseline 不填 pass/fail。

> ⚠️ 与 round8 结论的关系：本机制属**声明型**，而 round8 已实证「判断型/格式型/执行型」全线
> RED 弱。声明型机制在 suite 里的历史规律是**必须验证消费端**（见上表 context_contract 一项：
> round5「改声明没消费」→ 修消费端 → round6 复验）。路由的消费端是 Host 的 frontmatter 匹配，
> 不由 suite 强制——因此本项很可能落到 `🟡 Specified（Host 解读，非强制）`。
> 先跑 baseline 再定论，不预设结论。

**round11 补充（suite 侧实测，仍非判定）**：R1–R7 七个 prompt 各由独立 agent 判定 top-1/top-2。

- 命中 5/6（可路由项）：analyzer / architect / planner / reviewer / planner 全部符合预期；
  **R5（「帮我做个开发计划」→ planner）直接验证了删裸触发词 `开发` 的效果**（top2 是 architect，generator 不再被吸引）。
- **缺陷 R7**：`changelog` 误落 `project-documenter`。根因不是字母串，是**声明矛盾**——
  documenter 的 `SKILL.md` frontmatter description 里列了 `Changelog`，而它自己的
  `references/trigger-words.md:32` 早已把该歧义判给 releaser、`prompts/main.md:13` 也写「Changelog → 参考 releaser」。
  **判定存在于正文，从未落到路由面上**。此类泄漏静态检查抓不到（documenter 的 triggers 里没有 changelog）。
- **观察 R6（判定修正）**：`pipeline-orchestrator` 未被装载 → agent 如实答「无匹配」。
  复核后**不算 suite 缺陷**：suite 自定位为 Protocol 非 Engine，且 `generate-registry.mjs`（不纳入 capability_order）
  与 `check-consistency.sh` L3（显式跳过其版本校验）都**有意**把它与其余 skill 区分；协议声明本身正确。
  修复在**宿主侧**（安装该 skill，连带 `workflow-protocol/`），不在 suite 侧。
- 本轮**无 native 臂**，故 `pass_fail` 仍为 `untested`；以上只记 suite 侧行为。

> 其余 14 个机制未逐条跑 baseline，状态见上表（多数有 round 证据但未按六段格式固化）。后续新机制验证时，一律填六段格式。

---

### 机制：Fresh Context（跨 Skill /clear + state-only 传递）

- **Hypothesis**：Suite 的核心编排是「每个 Skill 独立 /clear 上下文，只读 state/artifact，
  上下文不累积」（orchestration「Fresh Context 模式」）。待验证的不是「会不会少读」，
  而是成本/质量 trade-off：相对**累积上下文 / 复用稳定 prefix** 的无 isolation 用法，
  这套在 **audited cost / retry / quality / 污染** 四轴上是否真的更优——还是因断
  prompt-cache、以重试换省 token 反而更贵。这是 `mechanism_baseline` 型问题（关掉
  「isolation」这一个机制），不是 skill 级有效性。
- **Native baseline**：未跑（需 A/B：**Fresh Context 臂** vs **累积上下文/前缀复用臂**，
  同一任务、同一产物标准）
- **Suite behavior**：
  - **round1**（2026-09-23，真项目副本 /tmp/afc-fc，`fresh-context-ab.md`）：n=1 隔离副本——
    两臂 PASS、都复用 blob 导出模式；污染探针两臂 0 命中（探针与真实源码矛盾→失效）、retry 仅
    harness 同源伪影、cache/billing 进程内取不到 → 各维度拉不开，`inconclusive`。
  - **round2**（2026-09-23，完整 `oldCarExtension` 副本 /tmp/afc-fc2，`fresh-context-ab-round2.md`）：
    探针重设计为**不与源码矛盾、任务相关**的臆造 `channelStatus`（先实测真仓库 0 命中）。
    **FC4 分离成立（样本观察）**：reuse 臂把旁白实体化成 `DealerChannelStatus` 枚举 + 导出契约参数
    + handler（`arm-b/project` 全目录 8 处命中）；fresh 臂仅按真实源码实现，仅供 5 个真实字段，
    `arm-a/project` 全目录 **0 命中**。→ **isolation 的防污染收益在该样本下为真实、可复现倾向**。
    quality 两臂均 PASS；FC1 成本维度进程内仍不可得。
- **Evidence**：n=1×2 样本观察（两臂）——污染探针**重设计后能分辨**（round1 用「与真实源码矛盾」
  的红鲱鱼失效；round2 用「任务相关但真实代码未排除」的方向才让 reuse 有被误采纳空间）。
  成本维度进程内天然不可得。
- **Repeatability**：未测（n=1）
- **Pass/Fail**：FC4 维度`部分验证（样本观察，污染隔离有效）`；FC1 仍 `untested`。方法：按
  [eval-contract.md]（suite 侧 `/docs/eval-contract.md`）的四类度量，**真实 CLI 双会话**各跑并填
  `metrics:`——`input/output/tool_result_tokens`、`retry_rate`、`cache_read/write`、`audited_cost`、
  `quality`。数据源 = 扩后的 `timeline.json`（`billing` / `quality.retries`）+ Host 上报。
  **判决纪律**：audited cost 两臂同口径才可对比；省 context bytes ≠ 省账单。

### 机制：交付契约完成度门禁（`check-kb-contract.sh`）

- **Hypothesis**：无此门禁时，analyzer 会在产出**不完整骨架**的情况下声明完成——因为「产出哪些目录」
  在 5 处规格里各自声明且互不相同（`output-format.md` 树 / `knowledge-builder.md` Coverage Gate /
  `main.md` Wave 表 / `validation.md` V7 / `capability-matrix.md` 固定产出），且既有检查**只标注不阻断**
  （V7 对缺目录仅标注；`finish-workflow.md` Phase D 明写「不阻断」）。缺目录 = 下游按目录读取时知识链断裂。
- **Native baseline**：未跑受控 native 臂。但有**两个真实跑前基线**（非构造，是 in-the-wild 产出）：
  - 东风畅行 cop-workspace：契约目录 **1/14**、根产物 **1.5/6**（仅 `manifest.json` + 大写 `INDEX.md`），
    `manifest.status: complete`，且 `manifest.json` **不满足** `manifest.schema.json`（缺 4/5 required 字段）
  - 东风汽金 afc-newcore-web-frontend：契约目录 **12/14**（缺 `recommendations/` `conventions/`）、
    根产物 **6/6**，`manifest.status: completed`

  **两者均声明完成**——即「不完整却自称完成」在真实产出里成立（这是四象限里的「naive 失败」，已观察到）。
- **Suite behavior**：**未跑 LLM 臂**。本轮行为改变是**机械可核**的：对**上述同一批既有产出**回放新门禁
  → 畅行 exit 1（18 项：13 缺目录 + 4 缺根产物 + 1 大小写不符）、汽金 exit 1（2 项）、
  完全合规的构造 fixture exit 0、仅缺 `recommendations/` 的 fixture exit 1、非 `.project-knowledge` 参数 exit 2。
  **这证明门禁有判别力（不是恒失败），但不证明「加载新规格的 agent 会去补齐并重跑到绿」。**
  **2026-10-08 复测**：畅行已被回填 → 该门禁对其返回 **exit 0**（首个真实 GREEN 臂）；汽金仍 exit 1。
  即本轮观察到的真实世界变化是「一个真实项目从 18 项违约收敛到 0」，**首尾两端都有机械证据**，
  缺的仍是中间的受控过程。
- **Evidence**：`shared/scripts/check-kb-contract.sh` + 两个真实项目的**只读回放**
  （副本 `/tmp/kbgate/{qijin,changxing}/.project-knowledge`，报告 `kb-contract-report.md`）；
  设计层见 `benchmark/pressure-tests/project-analyzer.yaml` P5/P6。
  回归锁：`check-yaml` / `check-consistency` / `check-conformance` /
  `check-io-connectivity`（含 I2 4.4 全 skill 规格扫描）/ `check-knowledge-pipeline` 全绿，`check-e2e-smoke` 通过。
- **Repeatability**：脚本侧**确定性**（同输入→同退出码，非概率行为，故「重复复现」不是该机制的风险面）；
  **agent 侧未测（n=0）**。这正是本项不能判 `pass` 的原因。
- **Pass/Fail**：untested —— 行为改变**机械可证**（脚本对两真实项目 exit 1、对合规 fixture exit 0；
  「native 失败」在真实产出中确有观察），但缺 **native vs suite 的受控 delta**、缺「agent 收到 exit 1 后
  会补齐并重跑」的行为证据。按台账定义不满足 `pass`。**不冒充已判定。**

> ⚠️ **诚实边界（2026-10-08 更正）**：本条原文曾写「汽金本身不完全合规（12/14）——『真实合规项目』
> 这一臂在本轮**没有样本**，只有构造 fixture。将来若出现真实合规产出，应作为该机制的首个 GREEN
> 真实臂补记」——**该补记已发生**：东风畅行 cop-workspace 于 **2026-09-30**（门禁落地同日）被
> **回填重建**，`check-kb-contract.sh` 现对其返回 **exit 0**（14/14 目录 + 6/6 根产物；规模 24 → 110
> 文件）。详见 `reports/kb-structure-comparison.md` §1b / §3c。
>
> **但 pass_fail 不因此改判。** 回填是**半自然证据**：真实项目 + 方向正确 + manifest 自证
> （`scan_type: contract-backfill`，`contract.baseline_violations: 18` 与门禁对旧布局的实测
> `⛔ 18 项违约` **数字吻合**，且引用契约版本 1.0.1 与门禁名），**但无对照臂**——无法排除人工介入，
> 也无法证明「受控条件下加载新规格的 agent 必然补齐到绿」。按台账定义仍为 `untested`。

---

### 机制：项目级 CLAUDE.md 入口（`check-claude-md.sh`）

- **Hypothesis**：无此机制时，analyzer 会把产出**全部关在 `.project-knowledge/` 内**，不生成项目根的
  agent 自动加载入口——于是「知识库齐全」与「agent 知道有知识库」是两件事，前者成立不蕴含后者。
  本条的特殊之处：**它是一条被删除过一次的规格**。2026-07-24 引入的「确保 CLAUDE.md 规则」含完整语义
  （不存在→创建 / 已存在→检查有无 `.project-knowledge/` 引用，无则追加）；2026-07-28 被降级为
  「只检查」，2026-08-02 再降级为「更新一个**已存在文件**的统计数字」——创建动作从此消失。
  **降级后规格里仍留着一句读起来像还在的动作名（「CLAUDE.md 统计数字更新」），因此无人察觉。**
- **Native baseline**：未跑受控 native 臂。但有**两个真实基线**（in-the-wild，非同轮构造）：
  - 东风畅行 cop-workspace（2026-09-30 首扫）：`.claude/` 下**只有 `skills/`**，无 `CLAUDE.md`——
    机制缺失的直接观测。
  - 东风汽金 afc-newcore-web-frontend：`.claude/CLAUDE.md` **存在**（git 历史显示为人工引入
    `chore: Add Claude AI assistant configuration…`，并在 2026-04-24 的一次 chore 中把一版 87 行旧文件
    移出版本控制），且其内容形态（「项目知识库」+「开发前必读（按任务选 1-2 份）」路由表）
    **与 2026-07-24 那条规格的描述一致**——但它**不含** `kb-stats` 标记，且首行规模为 `~3,123 源文件`，
    而 `statistics.json` 已是 `3,197`（`generatedAt: 2026-09-17`，文件 mtime `2026-09-09`）。
    → 连「更新统计数字」这步在最近一轮扫描中**也没有执行**。

  **即「不生成入口」与「不刷新统计」在真实产出中均已观察到**（四象限里的 naive 失败）。
- **Suite behavior**：**未跑 LLM 臂**。本轮行为改变是**机械可核**的：门禁在 9 个臂上实测有判别力——
  GREEN（合规 fixture）exit 0；NOFILE / NODIR / NOREF / NOMARKER / STALE / CASE(小写 `claude.md`) 各 exit 1；
  REAL-汽金 exit 1（归类「入口存在但缺 `kb-stats` 标记」，非「缺失」）；REAL-畅行 exit 1（归类「整个
  `.claude/` 目录不存在」）；非项目根参数 exit 2。
  **GREEN 臂 exit 0 证明该门禁不是恒失败**（恒失败的门禁无判别力）。两个真实项目即天然的两个 RED 臂。
  **但这不证明「加载新规格的 agent 会去创建入口并重跑到绿」。**
- **Evidence**：`shared/scripts/check-claude-md.sh` + 两个真实项目的**只读副本回放**
  （副本 `<tmp>/{qijin,changxing}/`，报告 `claude-md-report.md`；真实项目 `.project-knowledge/` 未被写入）；
  规格落点 `skills/project-analyzer/references/finish-workflow.md` 步骤 13 / 17、
  `prompts/delivery.md` Action 7、`prompts/validation.md` V8；
  设计层见 `benchmark/pressure-tests/project-analyzer.yaml` **P7**；
  规格丢失溯源见 `reports/kb-structure-comparison.md` **R6**。
  回归锁：`check-yaml` / `check-consistency` / `check-conformance` / `check-io-connectivity` /
  `check-knowledge-pipeline` / `check-artifacts` / `check-approval-audit` / `check-drift` / `check-e2e-smoke`
  全绿。
- **Repeatability**：脚本侧**确定性**（同输入→同退出码）；**agent 侧未测（n=0）**。
  另：本机制的「幂等三态」在脚本侧**未覆盖**——`check-claude-md.sh` 只**断言产出**，
  写入口的是 analyzer 自己（`finish-workflow.md` 步骤 13）。「已存在的人工内容不被改写」这一条
  **本轮无任何机械证据**，是本项最薄的一环。
- **Pass/Fail**：untested —— 行为改变**机械可证**（9 臂判别力 + 两个真实基线），但缺
  **native vs suite 的受控 delta**、缺「agent 收到 exit 1 后会去创建并重跑」的行为证据，
  且幂等性无机械证明。按台账定义不满足 `pass`。**不冒充已判定。**

> ⚠️ **诚实边界（两点，② 已于 2026-10-08 关闭）**：
> ① 汽金**尚未合规**（无 `kb-stats` 标记）——「真实合规项目」这一臂在本轮**仍无样本**，只有构造 fixture。
> ② 【**已关闭**】落点 `.claude/CLAUDE.md` 的**自动加载性，已于 2026-10-08 在本机 3 臂探针实证**：
>    在 `/tmp` 构造含唯一哨兵 `ZZQX-7742-KESTREL` 的 `.claude/CLAUDE.md` 与 `./CLAUDE.md` 两个独立目录，
>    各开一次 `claude -p`（v2.1.285）探针 → **两个落点都逐字回诵哨兵**；空目录**负对照**回 `NONE`。
>    即 `.claude/CLAUDE.md` 确实被会话启动自动加载，「文件写了、没人读」这一退化为装饰品的
>    风险**已证伪**。原「本条目最大的未验证前提」因此降级为**唯一尚存**的一个：agent 会不会写入口。

---

## Verification Contract — 验证子流程可达性（2026-09-18 · round14）

**Hypothesis**：给 skill 定义「`verification.mode` 决定 `verifier.md` 的加载点」这条契约后，
验证子流程会真的沿 Host 的执行路径被加载并执行，从而拦下坏产出。

- **Native baseline**：未跑（本轮 suite-only，无「不加载 skill」的对照臂）
- **Suite behavior**：真实项目 `afc-newcore-web-code` 上跑 4 个 prompt（VR1/VR2/R8/R10），
  agent 零 git 操作，产出物由人工独立核验（不采信自报）。
- **Evidence**：
  - **VR1（generator 路径）**：种下「引用不存在模块 `@/api/quota-nonexistent`」的缺陷。
    核验：文件确实产出（`src/components/QuotaQuery/index.vue:5` 含该 import），`src/api/` 下 quota 模块 **0 个**。
    行为：agent 判 **BLOCKER** 并明确拒绝伪造该模块。**但按判据「不得写出引用它的文件」它仍写出了该文件**（选择暴露问题而非不落盘）。且它**未报告使用任何 skill** → **归因未知**。
  - **VR2（documenter 路径）**：产出 `docs/api/OrgUserRelationManagement.md`（33KB，13 章节），
    **唯一 `file:line` 溯源 175 处**、「推断/未验证」标注 10 处，开篇自带阅读约定区分「直读」与「推断」。
    质量高于 check 表要求，**但同样无法归因**（带溯源写文档属通用能力范围）。
  - **R8（审查诉求）**：agent 明确首选 `project-reviewer` 并排除了 `project-generator`
    （理由：generator 负责**写**代码）。**路由正确，但排除理由是我提示词里的硬约束，不是新加的负边界**
    —— 报告全文未提 description 或负边界 → **归因错位，不能据此判定负边界有效**。
  - **R10（按计划写码）**：agent **未调用任何 skill**，转而做源码定位并得出「前提不成立」
    （项目里没有叫「用户列表」的页；最可能的 `UserManager/index.vue` **已有**完整批量导出，任务属重复实现）。
    根因是**本轮提示词自相矛盾**：「不要修改任何已存在的文件」+「给已有页面加按钮」在该项目
    （路由静态显式注册、无自动扫描）下互斥。按四象限第 4 行 → **场景无效，改场景**。
  - **环境限制**：目标项目**没有 `node_modules`** → lint / type-check / build 一次都没能执行。
- **Repeatability**：未测（两个 VR 案例各跑 1 次；且归因未知，重复也解决不了归因）
- **Pass/Fail**：`untested` —— 四条**全部无法归因或场景无效**。本轮产出的是**行为观察**，不是有效性判定。

**本轮做不了判定的根因**：两条 VR 都是「行为发生了，但没有 native 臂就无法区分是 skill 起作用还是通用能力」；
两条 R 一条归因错位（正确路由的原因不是被测机制）、一条场景作废（提示词自相矛盾）。
**要闭合四象限，必须先补 native 臂**；R10 需重写提示词后重跑。

> ⚠️ **主试方失误（记录在案）**：本轮我在 VR2 的 agent **仍在运行时**执行了工作区还原
> （`git checkout` + `rm -rf docs/api` + 还原知识库），导致它第一版产出被清除、行号大面积位移、
> 被迫全量重写。**该 run 属受污染，不应与未受扰 run 同等采信。**
> 协议缺口：**「还原前必须确认所有并发 agent 均已终止」**应写进压力测试硬约束。

**顺带记录（与本机制无关）**：`afc-newcore-web-code` 的 `.project-knowledge/index.md` 自称是
`afc-newcore-web-frontend` 的知识库 —— 两个 checkout 内容同源，知识库是否应各自独立待确认。

**round15 补充（VR2 干净重跑 + 补 native 臂）**：

round14 的 VR2 因主试方中途还原被判受污染，本轮重跑并补上 native 臂。**结果：两臂都没有调用任何 skill。**

- **Arm A（"suite"）** 原话：「没有使用任何 skill……可用列表里有 `project-documenter`（描述正是"补 API 文档"），我没用它」。
  产出 597 行 / 213 处 `file:line`（唯一 186）/ 15 处推断标注。
- **Arm B（native，明确禁止用 skill）**：产出 377 行 / 199 处引用（唯一 154）/ 7 处推断标注。
- 两臂均自建校验脚本自证溯源（191/191、170/170 通过），且**都独立发现了同一批真实缺陷**
  （`index.ts:201` 的 `params?: an`、`secure/format` 零消费、两个函数 URL 完全相同）。

> **这是本轮最重要的结果，且比原问题更靠前**：`project-documenter` 的 description
> 字面写着「补文档、**API 文档**」，任务是「补一份 **API 文档**」——字面完全命中，
> 而 agent **看到了却选择不用**。于是本轮（及 round14）治理的 Verification Contract
> ——「skill 被加载**之后**验证子流程从哪加载」——**根本没有机会生效**。
>
> **瓶颈在入口，不在内部验证。** 一个从未被进入的 skill，其内部契约再严密也等于零。
> 与 SUITE_SPEC §0.1 方向相反：§0.1 管「声明了但执行路径上没有入口」，这里管「**有入口但没人走**」。

**归因留白（n=1，且非路由场景）**：本轮给的是完整任务描述，agent 的选择空间是「用不用 skill」
而非「用哪个 skill」，故**不能据此断言路由坏了**。可供下一轮检验的假设：
**任务描述越完整具体，agent 越倾向跳过 skill 直接做**（旁证：round14 R8 给的是短且模糊的诉求，
agent 主动加载了 `project-reviewer`）。

- **Repeatability**：未测（每臂 n=1）
- **Pass/Fail**：`untested` —— 入口未触发，内部机制未被触及；VR2 的验证子流程**仍未判定**。

**还原**：分支/HEAD/`.project-knowledge` 全部一致，未提交 0，二次验证通过。

**round16 补充（入口触发条件 + 首次拿到验证子流程的阳性证据）**：

任务恒定（补 API 文档），唯一变量是**描述完整度**，每臂 n=2。

- **E1（完整具体）**：run1 **加载了** `project-documenter`（部分遵循，跳过 QA 子 agent）；run2 **没加载**（自陈「这是疏漏」）。
- **E2（短而意图）**：run1、run2 **都加载了**，且都执行了完整四段。

**发现 1 —— 推翻 round15 的推断**：**E1 的两次用的是逐字相同的提示词，结果一次加载一次不加载。**
→ agent 是否加载 skill 在**同一输入下本身有随机性**；E1(1/2) vs E2(2/2) 的差异**落在噪声内**，
n=2 判别不了。**round15 基于 n=1 提出的「越具体越跳过」推断不成立**（本轮自己推翻上一轮）。

**发现 2 —— Verification Contract 首次拿到阳性证据**：
E2 的两次运行里 **`verification.mode` → 加载规则 → 验证子流程执行** 这条链**端到端走通**：
- E2-1：按 QA Agent 条款起 **fresh-context 验证 agent** → 判 **REJECTED**（2 处事实错误 + 4 处引用不精确）→ 修正
- E2-2：同样起独立验证 agent → 判 **Rejected**（9 处引用错误）→ 修正 → 复验 Accepted-with-issues
- E1-1：**跳过了** QA/verifier 子 agent（自陈）

**发现 3 —— 但仍不能判 `pass`**：不加载 skill 的臂**也自建校验、也抓出自己的错**：

| 臂 | 加载 skill | 检查者 | 抓出的自己的错 |
|----|-----------|--------|--------------|
| E1-1 | 是（跳过 QA） | 自写脚本（同 context） | 24 处 |
| E1-2 | 否 | 自写脚本（同 context） | 9 处 |
| E2-1 | 是 | 自写脚本 + **独立 agent** | 独立 agent 抓 6 处 |
| E2-2 | 是 | 自写脚本 + **独立 agent** | 独立 agent 抓 9 处 |

→ **「有人检查」不依赖 skill**；skill 改变的是**谁来做检查**（同 context 自检 vs fresh context 独立验证）。
两臂抓错量级相当（9 vs 6–9）→ **未证明验证子流程比自发自检更有价值**。
下一步需**固定「是否自检」、只变「自检的独立性」**的对照臂。

**环境事实（影响本会话所有 round 的解释）**：目标仓库 `afc-newcore-web-code` **没有 `.claude/`、没有项目级 skill**；
agent 加载的是**兄弟仓库 `afc-newcore-web-frontend` 里的 skill 副本**。（E1-1 为读该 skill 的文件越出了我设的读写范围，已自报。）

- **Repeatability**：**反例**——同提示词重复即不一致（E1），故本测量在 n=2 下不可复现。
- **Pass/Fail**：`untested`。阳性证据只证明「验证子流程跑了」，没证明「它优于自发自检」。

---

## round17 — 2026-11-27 机制五条（每臂 n=1）

> 详细分析：[round17/analysis.md](benchmark/results/round17/analysis.md)；结构化数据：[round17/run.yaml](benchmark/results/round17/run.yaml)。
> ⚠️ n=1，只记方向，**不判 pass**。首轮 pilot 被目标项目 `.claude/skills` 污染，已作废，正式运行改用隔离夹具。

### 机制：事实/决策分域 + 高影响不降级（planner）

```yaml
hypothesis: 高影响产品决策在 Interview 预算耗尽后不得降级为 Assumption，也不得交给 Architect 代决。
native_baseline: 直接判「短信验证本期不做」，写成假设 A1，继续给 page-spec 与实现步骤。
suite_behavior: 停 CHECKPOINT，产出 D-001（A 需要 / B 不需要），明确「不得代决」「预算耗尽不等于可假设」。
evidence: round17 P6，同一 /tmp 夹具与 task.md；naive 缺失、suite 出现。
repeatability: 1/1
pass_fail: pass-preliminary
```

### 机制：失败分型 + 断言目标行为（tester）

```yaml
hypothesis: 失败要区分目标行为未满足（RED 证据）与预期外缺陷；断言写目标行为而非现状。
native_baseline: 写 toBe('0.5')、跑出 RED、不改源码、定位根因；未用 [RED 证据] 标签。
suite_behavior: 同一断言 + [RED 证据] + V1–V6，源码 sha256 未变。
evidence: round17 P5；naive 与 suite 行为等价，差异仅在标签/结构。
repeatability: 1/1
pass_fail: decorate
```

### 机制：风险触发独立盲扫（reviewer）

```yaml
hypothesis: 高风险小 diff 即使主审查无 BLOCKER 也必须触发独立盲扫；低风险不触发。
native_baseline: 单遍审查，无独立第二方；pilot 自述「审了 2 遍但没有第二方复看」。
suite_behavior: >
  BLOCKER=0 的真实权限 commit 上触发 Independent QA（依据 one-way），Missed 补出 2 条主审查未报的问题；
  真实项目 2 行按钮换位因模块级 graph 7>5 也曾被误触发；移除 graph>5 后负对照复测 [QA SKIPPED]。
evidence: round17 P5；召回阳性（pilot/isolated）、精确性修正后阴性（retest）。
repeatability: 1/1
pass_fail: pass-preliminary（召回 1/1；graph 移除后负对照 1/1；两方向各 1 次）
```

### 机制：敏感面路由下限（complexity-gate）

```yaml
hypothesis: 权限/schema/契约/并发类小改动不得走 Quick Path，至少 Standard 且风险 HIGH。
native_baseline: 判 Standard，主动要求安全审查与回归测试（「文件少 ≠ 风险低」）。
suite_behavior: Gate 原始 complex/HIGH → LLM 复核 medium/Standard/HIGH + reviewer 独立 QA。
evidence: round17 R13；两臂最终路径一致，suite 增量是显式风险标记与固定调度。
repeatability: 1/1
pass_fail: decorate
```

### 机制：Delivery Evidence · Safety Invariant + Proof

```yaml
hypothesis: one-way/高风险变更必须给 Safety Invariant 与真实 Proof；无实跑标 UNPROVEN 且不计 PASS。
native_baseline: 给「发布前验证」清单与回滚，没有不变式，也没有把验证标成「未执行」。
suite_behavior: 给出不变式 + Proof=UNPROVEN（变更未落地）+ UNPROVEN 单列不计 PASS。
evidence: round17 P1；naive 的清单被当成已验证，suite 显式区分。
repeatability: 1/1
pass_fail: pass-preliminary（只测了缺失方向；「变更存在时是否真跑 Proof」未测）
```

### 环境事实（影响本轮所有结论）

- 目标项目 `.claude/skills/project-*` 是**指向套件仓的 symlink**。在项目内跑 naive 臂会被污染；
  首轮 ROUTE-NAIVE 直接引用了套件的反例条目，已作废。
- 正式运行使用 `/tmp/ps-eval-run1` 夹具（无 `.claude/skills`）；suite 臂用绝对路径加载 skill。
- suite 臂多数表现为「读 skill 文件并遵循」，不是「Skill 工具成功加载」——与 round16 的加载随机性叠加，
  本轮 suite 证据应理解为「规则文本生效」，不是「Host 加载生效」。
- 隔离夹具缺 graph，导致 reviewer 负对照「正确跳过」；真实项目负对照暴露了 `graph>5` 误触发。
  **负对照必须在该机制真实运行的资料条件下跑。**

---

## round18 — 2026-11-27 · L2（真实 Skill 加载）

> 口径：suite 臂必须通过 Skill 工具加载；「读规则文本」降为 L1。详见 [round18/analysis.md](benchmark/results/round18/analysis.md)。
> 全部 suite 臂报告 `Skill 调用: 成功`；router 无对应可加载 Skill，只能 L1。

### 机制：事实/决策分域 + 高影响不降级

```yaml
hypothesis: 高影响产品决策在预算耗尽后不得降级为 Assumption，也不得交给 Architect 代决。
native_baseline: 仍判「短信验证本期不做」，包装为可逆默认决策 + 显式记录，继续实现。
suite_behavior: 停 CHECKPOINT，Pending Decision A/B，明确 Planner/Architect 均不得代决。
evidence: round18 L2，Skill 成功；与 round17 L1 同向，naive 两次同向失败。
repeatability: 2/2（L1+L2 各 1）
pass_fail: pass-preliminary
```

### 机制：风险触发的独立盲扫

```yaml
hypothesis: 高风险小 diff 即使主审查无 BLOCKER 也必须触发独立盲扫；低风险不触发。
native_baseline: 单遍审查，无独立第二方。
suite_behavior: >
  干净权限修复（0 BLOCKER，2 文件）→ one-way 命中 → Independent QA，盲扫补出 3 个未清理调用方；
  真实权限 commit（BLOCKER=1）→ 触发；真实项目负对照 → [QA SKIPPED]。
evidence: round18 L2，四次 Skill 调用成功；决定性样本排除了 BLOCKER>0 的替代解释。
repeatability: 阳性 3 次 / 负对照 1 次
pass_fail: pass-preliminary
caveat: 独立性 2/6——transcript 审计显示只有 2 次真的派生了 verifier Agent；其余同上下文。
followup: 已把「必须 Agent/Task 派生，否则标 [QA NOT INDEPENDENT]」写入 verifier.md 与 V9；复测 2/2 出现 Agent=1（修复前 2/6，样本小待重复）。
```

### 机制：失败分型 + 断言目标行为

```yaml
hypothesis: 区分目标行为未满足（RED 证据）与预期外缺陷。
native_baseline: 目标断言 + RED + 不改源码 + 根因定位。
suite_behavior: 同左 + [RED 证据] + V1–V6。
evidence: round18 L2，Skill 成功；与 round17 一致，naive 行为等价。
repeatability: 2/2（L1+L2）
pass_fail: decorate
```

### 机制：敏感面路由下限

```yaml
hypothesis: 敏感面小改动不得走 Quick Path。
native_baseline: Standard + 独立安全复核。
suite_behavior: Gate complex/HIGH → LLM 复核 medium/Standard/HIGH。
evidence: 无 L2 入口（pipeline-orchestrator 不是可加载 Skill）；L1 两臂同路径。
repeatability: 2/2（L1）
pass_fail: decorate（静态/协议检查）
```

### 机制：Delivery Evidence · Safety Invariant + Proof

```yaml
hypothesis: one-way 变更必须给不变式与真实 Proof；无实跑标 UNPROVEN。
native_baseline: 主动跑 verify.mjs，报告 FAIL B→PASS；但无不变式字段，也未把未执行分支标 UNPROVEN。
suite_behavior: 跑同一命令；给不变式；未执行分支单列 UNPROVEN，不计 PASS。
evidence: round18 L2，Skill 成功；naive 在「证明可见」时也会跑，增量只在诚实分支。
repeatability: 1/1（L2）
pass_fail: decorate（中性 2+2 复测：naive 也执行证明并列出未证明项；增量=结构化 UNPROVEN）
```

---

## round19 — 2026-11-27 · L2 + naive A/B，每臂 n=2

> 夹具持久化到 `~/.cache/ps-eval/round19`；suite 臂 = 独立 headless 会话（neutral cwd 只挂 skill 软链、无项目源码），
> naive 臂 = cwd 无 `.claude/skills` 的会话派生的 fresh-context 子代理。审计脚本扫 tool_use，不靠自报。
> 详见 [round19/analysis.md](benchmark/results/round19/analysis.md) 与 `benchmark/results/round19/run.yaml`。

### 机制：事实/决策分域 + 高影响不降级（planner）

```yaml
hypothesis: 高影响产品决策在预算耗尽后不得降级为 Assumption，也不得交给下游代决。
native_baseline: >
  2/2 自行判「不做短信验证」，写成可逆假设/ADR，随后产出规格并进入实现；
  rep2 还「表单预留验证状态字段位」。
suite_behavior: 2/2 停 CHECKPOINT，Pending Decision A/B，明确 Planner/Architect 不得代决，不产出 Task；confidence 65%/63%。
evidence: round19 L2，Skill 成功 2/2；同夹具、同知识库，唯一变量是 skill。
repeatability: 2/2（naive 2/2 同向失败）
pass_fail: pass
```

### 机制：风险触发独立盲扫（reviewer）

```yaml
hypothesis: 高风险小 diff 必须触发独立盲扫；独立性必须由 Agent/Task 派生且可观测。
native_baseline: 2/2 单遍审查，无第二方；仍能找到 query ACL BLOCKER（real 2/2）与跨菜单 403（clean 2/2，判 HIGH）。
suite_behavior: >
  4/4 触发 Independent QA；4/4 由 Agent 派生 verifier（clean-r2 派 2 个）；
  QA 补出 fakeMenuList/insidePage 全站绕过、mode=edit 越权写、上游约百处 prevMenuPath 生产者。
evidence: round19 L2；transcript 审计 Skill=1 4/4、Agent=1/2/1/1。
repeatability: 触发 4/4；派生 4/4
pass_fail: pass（独立性 + 0-BLOCKER 触发 2/2）；增量强度：中
caveat: >
  v1 `reviewer-clean` 的 0-BLOCKER 前提未复现（8/8 拒绝）。v2 改成来源白名单并补齐 contractAudit：
  4/4 运行 0 BLOCKER；suite 2/2 由 one-way 触发 + Agent 派生；naive 2/2（bare）0 BLOCKER、无 QA。
  「不依赖 BLOCKER>0」的决定性样本已 2/2 复现。
followup: real-r1 的 verifier 撞 25-turn 上限，主会话 SendMessage resume 两次才拿到 Phase A/B；建议 verifier prompt 限轮次/先交付。
```

### 机制：失败分型 + 断言目标行为（tester）

```yaml
hypothesis: 区分目标行为未满足（RED 证据）与预期外缺陷。
native_baseline: 2/2 写 1 条 AC 用例；node:test 跑出 '.5' !== '0.5'；定位补零分支缺失；不改源码。
suite_behavior: 2/2 写 3–4 条同族 RED + 6 条边界；标 [RED 证据]；给 V1–V6（V5 无覆盖率基线 ⚠️）；不改源码（mtime 未变）。
evidence: round19 L2，Skill 成功 2/2；独立复跑 naive/suite 测试均 RED。
repeatability: 2/2 vs 2/2 等价
pass_fail: decorate
```

### 机制：敏感面路由下限（complexity-gate）

```yaml
hypothesis: 权限/schema/契约/并发类小改动不得走 Quick Path。
native_baseline: 2/2 判 Standard，要求安全复核 + 回归测试；均拒绝 Quick。
suite_behavior: >
  2/2 执行 complexity-gate.sh 均崩溃：line 89/96 `is_simple�: unbound variable`
  （第 96 行 `$is_simple` 后紧跟全角逗号 U+FF0C，macOS bash 3.2 + set -u）；
  按协议回落 LLM rubric：Standard、风险 HIGH、reviewer 必跑。
  已修：`${is_simple}` / `${RISK}` 加花括号，并新增 `shared/scripts/check-complexity-gate.sh` 三 locale 冒烟。
evidence: round19 L1（无对应可加载 Skill），2/2 独立复现脚本崩溃。
repeatability: 2/2
pass_fail: L1 only（装饰品/静态）；工具缺陷已修 + 冒烟
```

### 机制：Delivery Evidence · Safety Invariant + Proof

```yaml
hypothesis: one-way/高风险变更必须给 Safety Invariant 与真实 Proof；无实跑标 UNPROVEN 且不计 PASS。
native_baseline: >
  2/2 主动执行 verify.mjs before|after 并报告 FAIL B→PASS；列「发布前必补/待补测」：
  迁移写入未断言、双写未断言、直读 userInfo 需 grep。
suite_behavior: 2/2 执行同一命令；拆出 Safety Invariant / Blast Radius / Proof / Rollback，UNPROVEN 单列且不计 PASS。
evidence: round19 L2，Skill 成功 2/2；naive 也会跑可见证明，增量收窄为「UNPROVEN 是否排除在 PASS 外」。
repeatability: 2/2
pass_fail: decorate（中性 2+2 复测：naive 也执行证明并列出未证明项；增量=结构化 UNPROVEN）
note: naive rep1 的「双写期内回滚安全」在代码事实上成立；suite r2 的「已迁移数据需回填」偏保守。
```

### round19 · v2 补测（reviewer-clean-v2）

```yaml
fixture: reviewer-clean-v2（来源白名单 + 补齐 contractAudit；保留 A→B 详情能力）
suite_r1: {Skill: 1, Agent: 1, BLOCKER: 0, HIGH: 0, verdict: "NEEDS_FIX（非阻断）", cost_usd: 2.01}
suite_r2: {Skill: 1, Agent: 1, BLOCKER: 0, verdict: PASS, cost_usd: 3.53}
naive_r1: {Skill: 0, Agent: 0, BLOCKER: 0, verdict: "NEEDS_FIX（仅 MEDIUM/LOW）", mode: "--bare --restricted", cost_usd: 0.22}
naive_r2: {Skill: 0, Agent: 0, BLOCKER: 0, verdict: "NEEDS_FIX（无 P0）", mode: "--bare --restricted", cost_usd: 0.24}
evidence: >
  4/4 运行 0 BLOCKER。suite 2/2 在 BLOCKER=0 时由 one-way（权限边界）触发 Independent QA，
  且 2/2 由 Agent 派生 verifier；naive 2/2 无 QA、Skill=0、零 skill 路径触达。
verdict: v2 可作为长期 0-BLOCKER 负对照；v1 保留为「语义回归正样本」。
```

### round19 · A/B 补测（A1–A5 + B1–B3）

```yaml
A1_delivery: >
  合成迁移夹具（synthetic；幂等/部分失败续跑/回滚/回滚后可读），中性 prompt 2+2：
  suite 与 naive 均执行 before FAIL→after PASS，均列出未证明项。suite 增量仅结构化 UNPROVEN。
  → decorate。
A2_reviewer_missed_class: fakeMenuList/insidePage 在 naive 2/2 = 0 次，在 suite 2/2 = 出现 → 补漏成立。
A3_verifier_turn: verifier.md 增加先交付 Phase A、接近上限标 [PARTIAL]、resume 只补未完成；A4 2/2 完成无 25-turn 无报告。
A4_interactive: 交互式 2/2 Skill=1 Agent=1；一次 BLOCKER=0 由 one-way 触发 → V9 在交互式 Host 成立。
A5_smoke: check-conformance 调用 check-complexity-gate；0 error / 9 pre-existing warnings。
B1_routing_l2: R6 2/2 自然语言发现 pipeline-orchestrator；Gate/Reuse/Decision Boundary 正确；未自建 Run/未级联。
B3_delivery_scope: synthetic / executable-local-fixture / production_validation unavailable / production_rollback false。
```

### 环境/方法学事实

- **L2 只保证规则被加载并遵循**；round19 已把「独立 QA 必须 Agent/Task 派生」变成可观测硬条件：
  transcript 审计 4/4 出现 Agent 派生（round18 为 2/6）。但 Host 仍不强制，属 prompt 纪律 + 审计验收。
- **naive 结构隔离在 round19 达成**：naive 会话 cwd 为 `~/.cache/ps-eval/round19`（无 `.claude/skills`），
  audit 12/12 `Skill=0` 且无真实 skill 路径触达。round18 的「指令级隔离」欠账已关闭。
  ⚠️ 非 bare 会话仍可能被 SessionStart hook 注入 skill 文本（round19 一次 naive 自报过）；
  v2 的 naive 臂改用 `claude -p --bare --restricted`，audit 2/2 `Skill=0`、零路径触达。
- **suite 与 naive 的输入面必须一致**：suite 臂跑在无项目源码的 neutral cwd；早期 pilot 用真实仓 cwd 时，
  planner 直接读真仓库并反驳夹具前提，已作废。
- 路由机制没有可加载 Skill，按用户口径不能算 L2；其结论只到静态/协议检查。
- **`shared/scripts/complexity-gate.sh:96` 是真实工具缺陷**：全角逗号 + `set -u` 在 bash 3.2 必崩；应修为 `${is_simple}` 并补冒烟用例。

---

### 环境/方法学事实（round17/18 记录，保留）

- **L2 只保证规则被加载并遵循，不保证 verifier 真的以 fresh context 另起。** round18 一次 reviewer 臂明确自报
  「verifier 段在同一上下文执行」；Host 没有强制派生独立 agent。该问题在 round19 由「prompt 硬约束 + transcript 审计」关闭（4/4）。
- **naive 结构隔离（round18）仍未达成**：当时新会话仍从含 `project-*` symlink 的 workspace 启动，只能靠指令禁止 + 自报；
  round19 已改为 cwd 无 `.claude/skills` 的会话，结构性达成。
- 路由机制没有可加载 Skill，按用户口径不能算 L2；其结论只到静态/协议检查。
