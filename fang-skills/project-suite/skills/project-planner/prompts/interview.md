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
| UI Pattern | FormWrapper 是所有表单的标准 | 需要哪些字段？有没有特殊校验？是否上传？ |
| Data | 用户模块已有 UserStore, UserAPI | 是否需要新的数据源？是否需要关联已有 API？ |
| Permission | 项目使用路由守卫 | 是否需要权限控制？哪些角色？ |
| Workflow | 审批流程使用 creditWorkflow | 是否需要审批？几级审批？ |
| Export | 项目使用 exportGraphImage | 是否需要导出功能？ |

## Question Template

每轮 ≤3 个问题，基于 Knowledge Gap 生成：

```
🔍 还需要确认：

1. [基于已知 knowledge 的追问]
2. [识别到的知识缺口]
3. [边界 case]

例：
🔍 还需要确认：
1. 项目已有 BaseForm 模式——个人信息表单需要哪些字段？（姓名/手机/邮箱/头像？）
2. 是否需要审批流？（项目已有 creditWorkflow 可复用）
3. 是否关联已有客户数据？（需查询 CustomerAPI 还是新建？）
```

## Exit

信息足够 → confidence ≥ 0.7 → 输出 `requirement-spec.md` → 进入 Code Audit：

```markdown
# Requirement Spec: 新增个人信息登记

## Confirmed
- 使用 BaseForm 模式（项目 conventions）
- 字段: 姓名, 手机, 邮箱, 头像（上传）
- 无需审批流
- 关联已有 CustomerAPI（通过 customerId）

## Assumptions
- 假设单用户单条记录（不涉及多条个人信息）
- 假设头像使用已有 BigFileUpload 组件
- 假设移动端适配（项目有 h5/ 目录）

## Open Questions
- 是否需要邮箱验证？（留给 Architect 决策）
```

## Domain-Aware Questioning（活 Domain Model）

Interview 不只是一次性提问，而是**读写项目 Domain Model**。

### domain/vocabulary.yaml 结构

`.project-knowledge/domain/vocabulary.yaml`（Analyzer 提取 + Interview 维护）：

```yaml
terms:
  - id: customer
    name: "客户"
    definition: "已完成实名认证的用户"
    kind: entity           # entity | value_object | workflow | role
    relationships:
      - { to: user, relation: "is_a_kind_of" }
    status: confirmed      # candidate | confirmed | conflicting
    source: interview      # analyzer | interview
    confidence: 0.9
```

### Interview 三步读写

```
1. 读：提问前查 domain/vocabulary.yaml → 已有定义不重问，用项目语言提问
2. 查：发现假设与已有定义冲突 → 标 ⚠️ Domain conflict，追问澄清
3. 写：确认新术语/关系 → 写入 vocabulary.yaml（status: confirmed）
```

### 冲突示例

```
Planner 假设 "Customer = 任意登记人"
  ↓ 读 domain model
发现: "Customer = 已完成实名认证的用户" (status: confirmed)
  ↓
⚠️ Domain conflict:
  Existing:  Customer = 已完成实名认证的用户
  Current:   Customer = 任意登记人
  Need:      "这里的 Customer 指哪个？"
```

→ [Glossary Extractor](../project-analyzer/prompts/extractors/glossary.md)
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

→ [Promotion Reviewer](../project-analyzer/prompts/promotion-reviewer.md)

## 与 Context Resolver 的关系

Interview 不替代 Context Resolver——Interview 追问**用户不知道的事**，Resolver 查询**项目已经知道的事**。两者互补：

- Resolver: "项目已有什么？" → BaseForm, CustomerAPI, creditWorkflow
- Interview: "用户想要什么？" → 哪些字段, 是否审批, 是否导出
