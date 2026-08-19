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
| <0.5 | Deep Interview + Planning Loop（≤5 questions, 用完做 Assumption） |

Context Resolver 已回答的 → 不重复问。Budget 用完 → 写 Assumption。

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
- 使用统一表单封装（项目 conventions）
- 字段: 姓名, 手机, 邮箱, 头像（上传）
- 无需审批流
- 关联已有用户 API（通过用户 id）

## Assumptions
- 假设单用户单条记录（不涉及多条个人资料）
- 假设头像使用已有上传组件
- 假设移动端适配（项目有对应目录）

## Open Questions
- 是否需要邮箱验证？（留给 Architect 决策）
```

## Domain-Aware Questioning（活 Domain Model）

Interview 不只是一次性提问，而是**读写项目 Domain Model**。

### domain/vocabulary.yaml 结构（v2 三分模型）

`.project-knowledge/domain/vocabulary.yaml`（Analyzer 提取 + Interview 维护），三分：`entities` / `actions` / `artifacts`（详见 [Domain Model](../../../runtime/contracts/domain-model.md)）：

```yaml
entities:   # 领域实体（名词）
  - id: order
    name: "订单"
    status: confirmed

actions:    # 领域动作（动词）
  - id: refund
    name: "退款"
    status: confirmed

artifacts:  # 领域产物（实体×动作 → 页面/API 命名）
  - id: orderRefundRecord
    name: "订单退款记录"
    composed_of: { entity: order, action: refund, artifact_kind: record }
    naming: "orderRefundRecord"
    status: confirmed
```

### Interview 三步读写

```
1. 读：提问前查 domain/vocabulary.yaml → 已有定义不重问，用项目语言提问
2. 查：发现假设与已有定义冲突 → 标 ⚠️ Domain conflict，追问澄清
3. 写：确认新术语/关系 → 写入 vocabulary.yaml（status: confirmed）
```

### 冲突示例

```
Planner 假设 "User = 任意登录者"
  ↓ 读 domain model
发现: "User = 系统注册用户" (status: confirmed)
  ↓
⚠️ Domain conflict:
  Existing:  User = 系统注册用户
  Current:   User = 任意登录者
  Need:      "这里的 User 指哪个？"
```

→ [Glossary Extractor](../../project-analyzer/prompts/extractors/glossary.md)
→ [Domain Model](../../../runtime/contracts/domain-model.md)

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
