# Context Resolver v1.0

> Task → Tags → Query graph.json → Curated Knowledge Injection。
> 解决"1000 篇知识，Planner 读哪些？"的问题。

## 工作流

```
用户: "新增登记个人信息"
        │
        ▼
Context Resolver: 提取 tags → [form, user, upload, validation, register]
        │
        ▼
Query graph.json:
  @knowledge:type=pattern,convention,principle,decision tags=form,user,upload,validation,register
        │
        ▼
Curated Result (top 10, sorted by score):
  1. pattern.form-wrapper       (score: 9.1, tags: form, vue3)
  2. convention.form-naming      (score: 8.5, tags: form, naming)
  3. principle.always-form-wrapper (score: 9.3, tags: form, principle)
  4. decision.form-validation    (score: 7.8, tags: form, validation)
  ...
        │
        ▼
Inject into Planner context → Planner 不需要 read 全部 .md
```

## Tag 提取

从用户任务描述中提取关键词 → 映射到 knowledge tags：

| 用户关键词 | knowledge tags |
|-----------|---------------|
| 登记/注册 | register, form, user |
| 个人信息 | user, profile, form |
| 上传 | upload, file, form |
| 审批 | approval, workflow, review |
| 列表/查询 | table, search, list |
| 表单 | form, validation, input |

## 三层 Context 模型

Context Resolver 一次回答三个问题，返回三个维度的 context：

| 层 | 来源 | 回答 | 类型 |
|----|------|------|------|
| **Long-term** | Knowledge Vault | 长期记住什么？ | 跨项目 Instinct/Playbook |
| **Project semantic** | .project-knowledge + graph.json | 应该怎么做？ | Patterns/Rules/Decisions |
| **Structural** | graph.json + Graph Query | 代码怎么连接？ | callers/callees/impact |

```
Context Resolver
  ├── Long-term  → Knowledge Vault（跨项目）
  ├── Semantic   → graph.json（项目语义）
  └── Structural → graph.json（代码结构）
```

Structural 层通过 [Graph Query Protocol](graph-query.md) 获取：

- `findConsumers(<目标>)` → 谁调用了它？影响范围
- `findDependencies(<目标>)` → 它依赖什么？耦合度
- `findImpacted([变更文件])` → 改动影响哪些节点？

## 注入格式

Resolver 输出精简的 knowledge summary，而非完整 knowledge object：

```yaml
# context-injection.yaml — Planner 消费
task: "新增登记个人信息"
resolved_at: "2026-08-05T12:00:00Z"

# 三层 context
long_term_knowledge:
  - { id: instinct.form-wrapper, statement: "Always use FormWrapper", scope: personal }

semantic_knowledge:
  - id: pattern.form-wrapper
    type: pattern
    statement: "所有复杂表单使用 FormWrapper 封装"
    confidence: 0.96
    score: 9.1
    why_relevant: "tag match: form"

  - id: principle.always-form-wrapper
    type: instinct
    statement: "Always use FormWrapper pattern for complex forms"
    confidence: 0.97
    score: 9.3
    why_relevant: "tag match: form, principle"

  - id: convention.form-naming
    type: convention
    statement: "表单组件命名: <Entity><Action>Form.vue"
    confidence: 0.89
    score: 8.5
    why_relevant: "tag match: form, naming"

  - id: decision.form-validation
    type: decision
    statement: "表单校验统一使用 Zod + vee-validate"
    confidence: 0.85
    score: 7.8
    why_relevant: "tag match: form, validation"

structural_facts:
  - { query: findConsumers(UserApi), result: "被 12 个模块调用, 改动影响范围广" }
  - { query: findDependencies(UserForm), result: "依赖 FormWrapper + docsStore + userAPI" }
  - { query: findImpacted([userId字段]), result: "3 个组件 + 2 个 API 受影响" }
```

## 集成

Planner Discovery 阶段第一步：调用 Context Resolver → 注入三层 context（long-term + semantic + structural）→ 然后做现状探查。
