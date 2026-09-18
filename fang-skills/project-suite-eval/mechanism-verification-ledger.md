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

### project-analyzer（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| Evidence Score 溯源（每条 Claim 附 file:line） | 额外动作 | 强 | ✅ 生效 | 基准：suite 量化证据密度（198 个 UsingGet 等），native 定性 |
| 先候选再验证（candidate-verify-accept） | 额外动作 | 强 | ✅ 生效 | round5：candidates/accepted/rejected 区分明确 |
| 增量分析（缺领域只跑相关 Extractor） | 额外动作 | 强 | ✅ 生效 | round5 N5-INC：5 个相关 Extractor，非全量 10 |
| 知识缺口入口（新鲜知识库跳过） | 判断 | 弱 | ⚠️ 未单独测 | round3/4 验证过「跳过 vs 不跳过」，但粒度 vs 增量分析重叠 |

### project-planner（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| Contract over Todo（9 模块契约） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 输出 todo list，suite 输出 9 模块契约 |
| 放置决议 target（module/domain/placement） | 额外动作 | 强 | ✅ 生效 | round6 M1：落点 customerManage（纠正 round5 的 baseData 错误） |
| Knowledge First（先扫描可复用资产） | 判断 | 弱 | ⚠️ 过程质量 | 结构化 REUSE/EXTEND/CREATE 裁决 vs naive ad-hoc |
| Confidence 透明（<40 拒绝产出） | 判断 | 弱 | ✅ 生效 | round5 P3：naive 硬编，suite 暴露 Gaps |

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

### project-reviewer（5 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 精确引用（每个发现 file:line） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也逐条 file:line，甚至挖得更细（RED 弱） |
| 可操作（每个问题附修复建议） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也给「位置/改什么/为什么」可执行修复（RED 弱） |
| 分级明确（五级符号 + 五轴） | 额外动作 | 中 | 🟡 部分生效 | round7 P4：naive 模糊三档，suite 精确五级+五轴 |
| AC 对照（逐条验证） | 额外动作 | 强 | ❌ 装饰品 | round8：naive 也逐条对照 AC + file:line（RED 弱） |
| 放置正确（V7 对照 target） | 判断 | 弱 | ⚠️ 纪律强制 | round7 V7：naive 也发现错位（LLM 通用），价值是「强制每次对照」降漏报率 |

---

## 跨 Skill 机制

| 机制 | 类型 | 验证状态 | 证据 |
|------|------|---------|------|
| context_contract 语义化（query 替代 .md） | 声明 | ✅ 生效（修复后） | round5 #1「改声明没消费」→ 修复消费端 → round6 复验 |
| convergence 统一协议 | 声明（Decision Protocol） | 🟡 Specified（Host 解读，非强制） | round6 M1b：产出 sufficient→handoff；「handoff 真交接」靠 Host 解读，非 Suite 强制 |
| knowledge-list → context-package | 声明 | ✅ 生效 | 静态收口 + benchmark 复验 |
| Reuse Check primitive | 额外动作 | ✅ 生效 | round5：结构化 REUSE/EXTEND/CREATE 裁决 |
| 跨 Skill 路由准确（措辞 → 正确 skill） | 声明 | 🟡 部分验证（suite-only） | round11：R1–R7 实测 top1 命中 **5/6**（可路由项）；另发现 2 处缺陷（R6 orchestrator 未装载→无匹配；R7 changelog 误落 documenter）。**无 native 臂，RED 仍未判** |

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
| ✅ 生效（RED 强） | 7 | 仅剩「增量分析」「Contract」「放置决议」有实测证据，其余 4 个（Evidence Score/先候选/决策可追溯/AC 驱动）仍理论分类待 Batch3 |
| 🟡 部分/声明生效 | 2 | 分级明确（部分）、convergence（Specified，Host 解读） |
| 🟡 一致性放大器 | 1 | 遵循项目模式——系统化遵循项目约定（value=一致性非质量，round10 实证） |
| ⚠️ 纪律强制（RED 弱） | 1 | 放置正确（强制每次对照，降漏报率） |
| ❌ 装饰品 | 14 | round8+10 实测 14 个机制全 RED 弱：判断型 6 + 格式型 6 + 执行型 2（LLM 通用能力覆盖） |
| 未验证 | 1 | 跨 Skill 路由准确（新增，仅有静态证据；其余 25 个机制已至少跑过 1 轮 baseline） |

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
