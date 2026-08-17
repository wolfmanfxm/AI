# Reuse Check — Suite Primitive v2.0.0

> Suite 一级复用判定原语。所有「造东西」的 Skill 在创建前必须走这一关——不是「帮你写代码」，而是先判断项目里是否已有东西可以复用。

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
Existing Capability Search（graph.json 节点 + catalog.md 登记 + grep 函数/组件名）
    ↓
┌─────────────────────┐
│ 完全覆盖 → REUSE    │  零改动，或 import 已有组件/API。需求已满足 = 满足（不重造）
├─────────────────────┤
│ 相近（需小改）→ EXTEND│  在已有组件上加 prop/slot/config，不复制粘贴
├─────────────────────┤
│ 语义不同 → CREATE   │  新建，但先复用已有子件（表单封装/表格封装/request 封装等）
└─────────────────────┘
```

## 三个判定问题（逐级问）

| # | 问题 | 判定 |
|---|------|------|
| 1 | **Existing?** 已有组件/页面/API 是否**完整覆盖**需求？ | 是 → REUSE（零改动）。已有组件完整覆盖需求时，直接复用不新建。 |
| 2 | **Similar?** 已有能力是否**相近**，只需小改（加 prop / 加 slot / 加 config 项）？ | 是 → EXTEND。别复制整个组件改两行。 |
| 3 | **Extend 不可行?** 语义确实不同、扩展会污染原组件？ | 是 → CREATE，但复用已有子件，标注「为何不复用」。 |

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
