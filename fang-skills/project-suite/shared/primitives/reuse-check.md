# Reuse Check — Suite Primitive v2.1.0

> Suite 一级复用判定原语。所有「造东西」的 Skill 在创建前必须走这一关——不是「帮你写代码」，而是先判断项目里是否已有东西可以复用。
> **v2.1（Create Gate）**：在 REUSE/EXTEND/CREATE 阶梯后新增一道向外找的 Create Gate——`CREATE` 唯一通路。判定顺序：项目内 → 语言 stdlib → 平台原生 → 已有第三方依赖 → 最小实现。**前置：先理解真实调用流，再判；最小化不得跳过阅读，也不得破坏正确性/契约完整性/明确要求**（对齐「Fewest Necessary Changes」原则）。

## 定位：生产者 / 消费者

| 角色 | Skill | 职责 |
|------|-------|------|
| **Producer** | analyzer | 产出 `catalog.md` + `graph.json`（Reuse Check 读的证据源） |
| **Consumer** | planner / architect / generator / refactorer | 创建前先跑 Reuse Ladder，判定 REUSE / EXTEND / CREATE |

> 使用方式：在 Skill 的 discovery / execution 阶段 `[引用](../../shared/primitives/reuse-check.md)`。

> 状态：**frozen / Suite Core Primitive**。REUSE / EXTEND / CREATE 阶梯为稳定决策，不再往里塞更多规则。

## 为什么是 Suite 一级

复用判定不该只藏在 generator 的 V2，它是**所有会「造东西」的 Skill 的第一道门**：没做结构化查重就新建，会产出已有组件的近重复件；查 catalog + graph 判定「需求已被完整覆盖」则零改动。

## 触发条件

任何任务里出现「新增 / 实现 / 创建 / 搭建 / 从零」的意图时，在动手写代码**之前**先执行本检查。

## Reuse Ladder（复用阶梯）

```
Before Create
    ↓
① Existing Capability Search（graph.json 节点 + catalog.md 登记 + grep 函数/组件名）
    ↓
┌─────────────────────┐
│ 完全覆盖 → REUSE    │  零改动，或 import 已有组件/API。需求已满足 = 满足（不重造）
├─────────────────────┤
│ 相近（需小改）→ EXTEND│  在已有组件上加 prop/slot/config，不复制粘贴
├─────────────────────┤
│ 语义不同 → CREATE   │  唯一通路：先过 Create Gate，再动手
└─────────────────────┘
    ↓
② Create Gate（跳出项目向外找，仍无才 CREATE）
    语言 stdlib → 平台原生能力 → 已有第三方依赖 → 最小实现
     ↓ 命中 → 用该替代，不新建
     ↓ 仍无 → CREATE，但复用已有子件（表单/表格/request 封装等），标注「为何不复用」
```

> **前置条件（对齐 Ponytail「lazy about the solution, never about reading」）**：
> 判 REUSE/CREATE 之前，先读真实调用流（谁调用、怎么调用、命中谁被谁依赖），再决定最小必要改动。
> 最小化只约束"改动数量"，不约束"阅读理解"。**不了解 flow 时，最小 diff 反而可能制造第二个 bug。**

## 三个判定问题（逐级问）

| # | 问题 | 判定 |
|---|------|------|
| 1 | **Existing?** 已有组件/页面/API 是否**完整覆盖**需求？ | 是 → REUSE（零改动）。已有组件完整覆盖需求时，直接复用不新建。 |
| 2 | **Similar?** 已有能力是否**相近**，只需小改（加 prop / 加 slot / 加 config 项）？ | 是 → EXTEND。别复制整个组件改两行。 |
| 3 | **Extend 不可行?** 语义确实不同、扩展会污染原组件？ | → 进 Create Gate（→4） |
| 4 | **Outside?（Create Gate）** stdlib / 平台原生 / 已有依赖能否最小替代？ | 是 → 用替代，不新建；否 → CREATE，复用已有子件，标注「为何不复用」。 |

## 查重证据来源（按优先级）

1. `.project-knowledge/components/catalog.md` —— 组件登记（结构化，最权威）
2. `.project-knowledge/graph.json` —— 模块/组件节点（查同名/近名节点）
3. `grep` 函数名/组件名 —— 兜底，确认实际引用与磁盘存在性

## 输出格式

每个「新增」意图，Discovery 阶段产出一条复用决策（对齐 Decision Record）：

```markdown
D[复用裁决]: [REUSE|EXTEND|CREATE]
  需求: <要造的东西>
  命中: <已有组件/API，或「无」>
  依据: <catalog.md 条目 / graph.json 节点 / grep 命中>
  结论: <零改动 | 扩展已有 X | 新建 Y（复用子件 Z）>
```

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 「看起来简单，直接新建」 | 仍先查 catalog.md + graph.json |
| 需求已覆盖还新建近重复组件 | REUSE 零改动（不新建重复组件） |
| 复制已有组件改两行当新组件 | EXTEND：给原组件加 prop/slot |
| 新建时忽略已有子件 | CREATE 也先复用已有子件（表单/表格/request 封装） |
| 项目内无现成组件就直接新建 | 先过 Create Gate：查 stdlib / 平台原生 / 已有依赖能否最小替代 |
| 不看 flow 就套「最小 diff」 | 先读真实调用流；改最少必要 producer + consumer，不做最小 diff/最少文件 |
| 为省 diff 只改声明不改消费者 | ✗ 假修复。改最少必要 Producer + Consumer + prove no drift |
