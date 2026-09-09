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

## 核心规律（round7 实证）

**「额外动作型」规则 RED 强，能改变行为；「判断型」规则 RED 弱，是 LLM 通用能力。**

- 额外动作型：先读源码、真跑测试、增量修改（Read 再 Edit）、精确 file:line 溯源 → LLM 默认不做，skill 纪律才让它发生
- 判断型：遵循模式、现状核实、够用就好、上下文驱动、对照 PLAN → LLM 通用能力覆盖，加不加 skill 没区别

---

## 各 Skill 机制台账

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
| 使用项目组件（Reuse Ladder） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 原生组件，suite 项目封装组件 |
| 增量修改（Read 再 Edit 不 overwrite） | 额外动作 | 强 | ✅ 生效 | round5 P2：diff 只含目标改动 |
| 完整性（loading/empty/error 全状态） | 额外动作 | 强 | ✅ 生效 | round5 P3：naive 只写 happy path |
| 遵循项目模式（不凭框架记忆） | 判断 | 弱 | 🟡 一致性放大器 | round10+复验：naive 复制最近模块（ad-hoc），suite 系统化遵循项目约定；项目用 any 是事实非 skill 缺陷——value=一致性非质量 |

### project-tester（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 可执行（生成后尝试运行） | 额外动作 | 强 | ✅ 生效 | round7 P4：naive 写完没跑，suite 真跑 vitest 8 passed |
| 先理解再测试（读源码理解边界） | 额外动作 | 强 | ✅ 生效 | round7 P3：naive 凭函数名猜错行为（猜错单位/返回类型），suite 读源码全对 |
| AC 驱动（每条 AC 至少一个用例） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 只测 happy path |
| 项目约定优先（自动检测框架） | 判断 | 弱 | ❌ 装饰品 | round10：naive 也检测 vitest + .test.ts 命名（LLM 通用能力覆盖） |

### project-reviewer（5 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 精确引用（每个发现 file:line） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 模糊反馈，suite 精确定位 |
| 可操作（每个问题附修复建议） | 额外动作 | 强 | ✅ 生效 | round7 P3：naive 空话，suite 具体修复代码 |
| 分级明确（五级符号 + 五轴） | 额外动作 | 中 | 🟡 部分生效 | round7 P4：naive 模糊三档，suite 精确五级+五轴 |
| AC 对照（逐条验证） | 额外动作 | 强 | ✅ 生效 | round5 P2 |
| 放置正确（V7 对照 target） | 判断 | 弱 | ⚠️ 纪律强制 | round7 V7：naive 也发现错位（LLM 通用），价值是「强制每次对照」降漏报率 |

---

## 跨 Skill 机制

| 机制 | 类型 | 验证状态 | 证据 |
|------|------|---------|------|
| context_contract 语义化（query 替代 .md） | 声明 | ✅ 生效（修复后） | round5 #1「改声明没消费」→ 修复消费端 → round6 复验 |
| convergence 统一协议 | 声明（Decision Protocol） | 🟡 Specified（Host 解读，非强制） | round6 M1b：产出 sufficient→handoff；「handoff 真交接」靠 Host 解读，非 Suite 强制 |
| knowledge-list → context-package | 声明 | ✅ 生效 | 静态收口 + benchmark 复验 |
| Reuse Check primitive | 额外动作 | ✅ 生效 | round5：结构化 REUSE/EXTEND/CREATE 裁决 |

---

## 统计

| 判定 | 数量 | 说明 |
|------|------|------|
| ✅ 生效（RED 强） | 15 | 额外动作型，benchmark 实证改变行为 |
| 🟡 部分/声明生效 | 2 | 分级明确（部分）、convergence（Specified，Host 解读） |
| 🟡 一致性放大器 | 1 | 遵循项目模式——系统化遵循项目约定（value=一致性非质量，round10 实证） |
| ⚠️ 纪律强制（RED 弱） | 4 | Knowledge First、Confidence 透明、放置正确、知识缺口入口（未单独测） |
| ❌ 装饰品 | 3 | 够用就好、上下文驱动、项目约定优先（LLM 通用能力覆盖，RED 不成立） |
| 未验证 | 0 | （项目约定优先已在 round10 验证） |

## 结论

**「设计好的机制」里，约 60%（15/25）真正改变了行为（额外动作型），1 个是一致性放大器（遵循项目模式，价值 = 忠实遵循项目约定），约 16%（4/25）是「纪律强制」（判断型 RED 弱），3 个是装饰品（够用就好、上下文驱动、项目约定优先），1 个声明了但 Specified 未强制（convergence）。round10 的实证结论：判断型机制里多数「naive 也做对了」（上下文驱动、项目约定优先 = 装饰品）；「遵循项目模式」是唯一有增量的判断型——它把 naive 的「复制最近模块」升级为「系统化遵循项目约定」，但价值是「一致性」不是「质量」，项目代码本身的好坏不属于 skill 的职责。**

这回答了元问题：**不是所有「设计好的机制」都改变行为。额外动作型改变行为，判断型是 LLM 通用能力（价值仅在降低漏报率），声明型必须验证消费端否则是「改了没生效」。**

---

## 回归基准记录（已实测机制，五段格式样板）

> 以下机制已在 round5/6/7 跑过 naive vs suite baseline，按五段格式固化。**这是回归基准的样板**——后续新机制、或改动的机制，都按这个格式验证。

### 机制：先理解再测试（tester 原则3）

- **Hypothesis**：无 skill 时 LLM 凭函数名猜行为，漏掉真实边界（单位/返回类型/异常）
- **Native baseline**：凭 `parseAmount` 函数名猜「解析金额为元」，发明不存在的 options，漏掉「分单位/NaN/thousand 字符串」三个真实边界
- **Suite behavior**：读源码后覆盖 NaN、分单位、thousand 字符串全部边界
- **Evidence**：round7 N7-PT-tester-P3（native 猜错 + suite 全对）
- **Pass/Fail**：✅ pass（RED 成立，额外动作型）

### 机制：可执行（tester 原则4）

- **Hypothesis**：无 skill 时 LLM 写完测试不实际运行就声称通过
- **Native baseline**：写完测试，未运行（「写完即可」自然行为）
- **Suite behavior**：`npx vitest run` 实际运行，8 passed
- **Evidence**：round7 N7-PT-tester-P4
- **Pass/Fail**：✅ pass（RED 成立，额外动作型）

### 机制：现状核实先行（architect 原则3）

- **Hypothesis**：无 skill 时 LLM 不核实现状，为已实现模块凭空设计
- **Native baseline**：把「客户列表」当全新功能设计（不知道 customerCompany/customerIndividual 已存在）
- **Suite behavior**：先 Code Audit 发现已实现 → 标记 [已实现] → 复用
- **Evidence**：round7 N7-PT-architect-P4（native 凭空设计 vs suite 先核实）
- **Pass/Fail**：✅ pass（RED 成立，额外动作型）

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

> 其余 17 个机制未逐条跑 baseline，状态见上表（多数有 round 证据但未按六段格式固化）。后续新机制验证时，一律填六段格式。
