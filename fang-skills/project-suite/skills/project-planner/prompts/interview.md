# Requirement Interview — Planner

> 借鉴 Matt Pocock grill-me：不停追问直到信息足够。不生成 Plan，只收集 Requirements。
> 在 Discovery 之后、Code Audit 之前执行（可选，复杂需求时启用）。

## 何时触发

由 [Completeness Check](completeness-check.md) 的多维评分驱动，不再用简单规则：

| planning_confidence | 行为 |
|-------------------|------|
| ≥0.9 | 跳过 Interview → 直接 Generate Plan |
| 0.7-0.89 | Light Interview（≤2 questions） |
| 0.5-0.69 | Standard Interview（≤3 questions） |
| <0.5 | Deep Interview + Planning Loop（≤5 questions，用完按影响分流） |

Context Resolver 已回答的 → 不重复问。

**Budget 用完时的分流**（不是一律写 Assumption）：

- 低/中影响缺口 → 写 Assumption（带 confidence），继续。
- 高影响未决项（`state: NEEDS_CLARIFICATION` 且 `impact: high`）→ **不得**降级为 Assumption。
  写进 `## Pending Decisions`，停在 CHECKPOINT 交用户拍板（或用户显式授权「按某假设执行」）。
  宁可停一步，也不把用户没做的产品决策伪装成已定。

## 事实 / 决策 / 方案：三类信息三种归属

> Interview 的职责边界：**事实靠查，决策靠问，方案靠比。** 三者不能互相顶替。

| 信息类型 | 例 | 归属 | 禁止 |
|---------|----|------|------|
| 项目事实（已有组件/模式/约束） | 有没有统一表单封装、现有 API 形态 | Context Resolver + Code Audit 查证 | 不得靠推测写进 Confirmed |
| 业务规则 / 产品行为 / 用户偏好 | 是否需要邮箱验证、哪些角色可审批、字段是否必填 | **问用户**（或用户明确授权按某假设执行） | 不得因为 Architect 能设计方案，就交给 Architect 决定「要不要」 |
| 技术方案选择 | 状态管理用 Store 还是 Composition API、接口怎么拆 | Architect 对比矩阵 / PoC / ADR | 不得在 Interview 里替用户定方案 |
| 低风险未知项 | 默认排序、空态文案 | Assumption + confidence | 高影响项不得走这条 |

判据：**「用户想要什么」是决策；「项目里已经有什么」是事实；「怎么实现」是方案。**
Resolver 查到的事实、用户答过的决策才能进 Confirmed；两者都没有 → Assumption（低影响）或 Pending Decisions（高影响）。
> 证据：eval ledger · `planner-decision-boundary`（高影响未决项不降级）。

## Interview 流程

```
Context Resolver → 了解项目已有 knowledge
      │
      ▼
Knowledge Gap Analysis → 缺什么信息？
      │
      ▼
Targeted Questions → 逐轮追问（每轮 ≤3 个问题）
      │
      ▼
Confidence Check → 信息足够？
      │  足够 → 进入 Code Audit
      │  不足 → 继续提问
```

## Knowledge Gap Analysis

Context Resolver 返回已有 knowledge → 识别缺口：

| 领域 | 已知 | 未知 → 追问 |
|------|------|------------|
| UI Pattern | 表单有统一的标准封装（具体名由 Resolver 注入） | 需要哪些字段？有没有特殊校验？是否上传？ |
| Data | 用户/账户模块已有 Store + API | 是否需要新的数据源？是否需要关联已有 API？ |
| Permission | 项目使用路由守卫 | 是否需要权限控制？哪些角色？ |
| Workflow | 审批流程有统一实现 | 是否需要审批？几级审批？ |
| Export | 项目有导出实现 | 是否需要导出功能？ |

## Question Template

每轮 ≤3 个问题，基于 Knowledge Gap 生成：

```
🔍 还需要确认：

1. [基于已知 knowledge 的追问]
2. [识别到的知识缺口]
3. [边界 case]

例：
🔍 还需要确认：
1. 项目已有统一表单封装——个人资料表单需要哪些字段？（姓名/手机/邮箱/头像？）
2. 是否需要审批流？（项目已有审批流实现可复用）
3. 是否关联已有用户数据？（查询已有 API 还是新建？）
```

## Exit

信息足够 → confidence ≥ 0.7 → 输出 `requirement-spec.md` → 进入 Code Audit：

```markdown
# Requirement Spec: 新增个人资料登记

## Confirmed
- 使用统一表单封装（项目 conventions）          ← 事实（Resolver / Code Audit 查证）
- 字段: 姓名, 手机, 邮箱, 头像（上传）          ← 用户答
- 无需审批流                                   ← 用户答
- 关联已有用户 API（通过用户 id）                ← 用户答

## Assumptions
- 假设单用户单条记录（不涉及多条个人资料）        ← 低影响推断
- 假设头像使用已有上传组件                       ← 低影响推断
- 假设移动端适配（项目有对应目录）                ← 事实 + 低影响推断

## Pending Decisions（高影响，需用户拍板）
- 是否需要邮箱验证？—— 产品行为决策，属于用户；**不问 Architect 代决**。
  若用户未答：Plan 以 `⚠️ 未决` 标注并停在此 CHECKPOINT，不写成 Assumption、不静默跳过。
```

## Domain-Aware Questioning — **未实现**

> 本节此前定义 Interview 读写 `domain/vocabulary.yaml`（相对 `.project-knowledge/`；活 Domain Model，v2 三分模型）。
> **摘除原因**：Analyzer 的 `runtime/registry/extractor-registry.yaml` 里**没有 domain extractor**——
> 也就是说 `vocabulary.yaml` **没有任何 Producer**，「读」这一步永远读不到东西。
> 它属于「先建一个 declaration area，再慢慢想 Consumer」，正是 SUITE_SPEC §0.1 与
> eval-contract 的 ablation 义务要挡的形态。
>
> **恢复条件**：Producer（domain extractor）+ Consumer + Verify **一次性闭环**后，再进入正式契约
> （届时需同时恢复 `knowledge-directories.yaml` 里对应的目录条目）。原始设计见
> [docs/archive/domain-model.md](../../../docs/archive/domain-model.md)。
>
> 术语一致性目前由 **Glossary** 覆盖，未受影响：
> → [Glossary Extractor](../../project-analyzer/prompts/extractors/glossary.md)

## Decision → Promotion 分流

Interview 产生的每个 Decision，不直接决定"写不写文档"。交给 Promotion Reviewer 判断：

```
Interview Decision
  → Promotion Reviewer 评分
    → Task-only (promotion:none)     → 仅保留在 Task Artifact
    → Project-level (promotion:project) → 写入 Project Knowledge
    → Cross-project (promotion:personal) → Knowledge Vault
```

→ [Promotion Reviewer](../../project-analyzer/prompts/promotion-reviewer.md)

## 与 Context Resolver 的关系

Interview 不替代 Context Resolver——Interview 追问**用户不知道的事**，Resolver 查询**项目已经知道的事**。两者互补：

- Resolver: "项目已有什么？" → 统一表单封装, 用户 API, 审批流
- Interview: "用户想要什么？" → 哪些字段, 是否审批, 是否导出
- Architect: "怎么实现最好？" → 方案对比与 ADR；它回答「要不要」以外的部分
