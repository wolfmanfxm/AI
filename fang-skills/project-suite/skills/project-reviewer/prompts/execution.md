# Execution — Reviewer

> @template: execution

## Actions

### 0. Graph 结构检查

→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)
- `findConsumers(<变更文件>)` → 本次改动影响哪些模块
- `findTransitiveDeps(<变更模块>)` → 传递依赖深度 ≤2，检查是否引入循环依赖
- 循环依赖检测命中 → 🔴 BLOCKER（架构级问题）

### 1. 必要性检查（Existential Gate，先于五轴）

> Question existence FIRST。五轴审「做对了吗」，本 pass 先审「这层/这个改动该不该存在」。
> 对齐 [Reuse Check Create Gate](../../../shared/primitives/reuse-check.md)，只标记不需要存在的结构，不修。

| # | 必要性钩子 | 命中信号 → |
|---|-----------|-----------|
| 1 | 新增 abstraction 有第二个真实消费者吗？ | 单消费者 → 🟡 建议内联。工厂只被一处实现 → 直接内联 |
| 2 | 新增 config 真的有变化需求吗？ | 恒为某值 / 无人改 → 🟡 硬编码，不引入配置层 |
| 3 | 新增 dependency 已有 stdlib / 平台原生 / 已有依赖替代吗？ | 有 → 🟠 换原生，不加依赖 |
| 4 | 新增 file/layer 是否形成真实 Producer + Consumer 闭环？ | 只有 Producer 无 Consumer（或反之）→ 🟠 假闭环，删 |
| 5 | 是否只改声明不改消费者（假修复）？ | 是 → 🔴 需补全最少必要 Producer + Consumer |

> ⚠️ 最小化**从属于**正确性与契约完整性：necessity 钩子只管"少加结构"，不得为省 diff 删掉有真实消费者的代码、破坏 API 契约或验收标准。

### 2. 五轴扫描

| 轴 | 重点 | Prompt |
|----|------|--------|
| 正确性 | 逻辑错误、边界条件、类型安全、状态一致性、API 契约 | [prompts/correctness.md](correctness.md) |
| 安全性 | 注入、XSS、敏感数据、权限、输入校验 | [prompts/security.md](security.md) |
| 可读性 | 命名、复杂度、注释、函数长度 | 通用检查 |
| 架构 | 模块边界、接口设计、复用、扩展性 | 若存在 ARCHITECTURE.md → 架构决策对照；否则通用检查 |
| 性能 | N+1 查询、渲染、内存、包体积 | 通用检查 |

每轴逐文件检查，每个发现标注 `file:line` + `修复方案`。

> 可选输入对照：discovery 若加载了 `ARCHITECTURE.md` → 架构轴逐条对照架构决策（模块边界/接口契约/选型），违反标 BLOCKER/HIGH；若加载了 `TEST-REPORT.md` → 正确性轴结合测试结果评估回归风险，未覆盖的改动路径标 `⚠️ 无测试覆盖`。

### 3. AC 对照

逐条验证 `# Acceptance Criteria` → 标注 ✅/❌/⚠️。不能验证的（主观描述）→ 标注 ⚠️ + 原因。

每个 finding（`F-xxx`）标注 `against: AC-xxx` —— 指向它违反的 AC，供 check-artifacts.sh 做 F→AC 追溯。

### 4. Scope 边界检查

变更是否超出 `# Scope` → 超出标注 `[SCOPE CREEP]`。

### 5. Candidate 验证

若 Generator 产出了 Candidate 知识 → 验证准确性 → 标注 confidence → 满足 R3 (>85) → 更新 `knowledge.json`。

### 6. 问题分级

| 🔴 BLOCKER | 🟠 HIGH | 🟡 MEDIUM | 🟢 LOW | 🔵 PRAISE |
|------------|---------|-----------|--------|-----------|
| 生产事故 | 大概率线上问题 | 代码质量改善 | 锦上添花 | 值得学习 |

→ 详细：[references/severity-guide.md](../references/severity-guide.md)

🔴 CHECKPOINT — 展示审查摘要（BLOCKER/HIGH/MEDIUM/LOW/PRAISE 计数）

## Verification（Candidate 验证子流程，**非 Stage**）

本阶段的产出先作为 **Candidate**，在 Exit 前加载 [verifier.md](verifier.md)，以 fresh context 执行独立验证；
只有 verifier 判为 **Accepted** 的 Candidate 才能进入 `validation` 阶段或被下游消费。

> 依据 `skill.yaml` 的 `verification: { mode: candidate-verify-accept }` → 见
> [workflow-protocol · Verification Contract](../../../workflow-protocol/SKILL.md)。
> ⚠️ verify **不是** stage：它不参与 stage progression，也不出现在 `interface.stages` 里。

## Exit

- 所有变更文件审查完成
- 问题已分级（BLOCKER→LOW）+ PRAISE 已记录
- AC 对照表完成

## Failure

| Condition | Action |
|-----------|--------|
| 文件过大无法完整读取 | 分段读关键区域（函数签名+分支+异常处理），标注 `⚠️ 未完整审查` |
| 不熟悉的语言/框架 | 仅做通用检查（命名/结构/注释），标注 `[超出审查范围]` |
| PLAN.md 缺失 | 从代码推断功能意图 → 降级为纯代码审查，标注 `⚠️ 无验收标准` |
