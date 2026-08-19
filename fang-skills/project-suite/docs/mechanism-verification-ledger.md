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

## 正式回归基准格式（每个机制应填的 5 段）

> 这是「回归基准」的标准结构。每个机制一行 Hypothesis，验证时填 baseline/suite/evidence/pass_fail。

```yaml
# 机制：<名称>
hypothesis: <这个机制应该改变什么行为？无 skill 时 LLM 会漏做什么？>
native_baseline: <不加载 skill 跑 scenario，实际发生了什么？>
suite_behavior: <加载 skill 跑同样 scenario，实际发生了什么？>
evidence: <round 号 + 任务名 + 可复现的证据>
pass_fail: pass | fail | decorate | untested
  # pass     = RED 成立（native 漏做，suite 做了）
  # fail     = 机制没生效（native 和 suite 一样）
  # decorate = 判断型，RED 弱（LLM 通用能力），价值是纪律强制
  # untested = 还没跑 baseline
```

**关键**：`native_baseline` 和 `suite_behavior` 必须来自真实 benchmark（naive vs suite 对比），不能凭空填。没有 baseline 数据的机制，标 `untested`，不假装「已验证」。

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
| 上下文驱动（选型对齐项目约束） | 判断 | 弱 | ⚠️ 纪律强制 | round7 P4：naive 也对齐了（LLM 通用能力） |
| 够用就好（不过度设计） | 判断 | 弱 | ❌ 装饰品 | round7：naive 也够用就好，RED 不成立 |

### project-generator（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 使用项目组件（Reuse Ladder） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 原生组件，suite 项目封装组件 |
| 增量修改（Read 再 Edit 不 overwrite） | 额外动作 | 强 | ✅ 生效 | round5 P2：diff 只含目标改动 |
| 完整性（loading/empty/error 全状态） | 额外动作 | 强 | ✅ 生效 | round5 P3：naive 只写 happy path |
| 遵循项目模式（不凭框架记忆） | 判断 | 弱 | ⚠️ 过程质量 | round7：naive 也遵循了，但 suite 类型化更强（零 any） |

### project-tester（4 原则）

| 机制 | 类型 | RED 假设 | 验证状态 | 证据 |
|------|------|---------|---------|------|
| 可执行（生成后尝试运行） | 额外动作 | 强 | ✅ 生效 | round7 P4：naive 写完没跑，suite 真跑 vitest 8 passed |
| 先理解再测试（读源码理解边界） | 额外动作 | 强 | ✅ 生效 | round7 P3：naive 凭函数名猜错行为（猜错单位/返回类型），suite 读源码全对 |
| AC 驱动（每条 AC 至少一个用例） | 额外动作 | 强 | ✅ 生效 | round5 P1：naive 只测 happy path |
| 项目约定优先（自动检测框架） | 判断 | 弱 | ⚠️ 未单独测 | 与 generator「遵循项目模式」同类 |

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
| ⚠️ 纪律强制（RED 弱） | 6 | 判断型，价值在「降低漏报率」非「从无到有」，需统计验证 |
| ❌ 装饰品 | 1 | 够用就好（LLM 通用能力覆盖，RED 不成立） |
| 未验证 | 1 | tester 项目约定优先 |

## 结论

**「设计好的机制」里，约 60%（15/25）真正改变了行为（额外动作型），约 25%（6/25）是「纪律强制」而非能力增强（判断型，RED 弱），1 个是装饰品（够用就好），1 个声明了但 Specified 未强制（convergence）。**

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

> 其余 20 个机制未逐条跑 baseline，状态见上表（多数有 round 证据但未按五段格式固化）。后续新机制验证时，一律填五段格式。
