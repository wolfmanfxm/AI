# Instinct Extractor

> Phase 6.5 — Classifier 之后、Delivery 之前。
> 从跨项目 personal_candidates 中提炼 Instinct（Always/Prefer/Avoid/Never）。

## 什么是 Instinct

Instinct 不是单个项目的 Pattern，而是**跨项目反复出现的规律**。

| 层级 | 范围 | 示例 |
|------|------|------|
| **Fact** | 单项目 | "afc-newcore 用 FormWrapper 封装表单" |
| **Rule** | 单项目 | "afc-newcore 所有表单必须用 FormWrapper" |
| **Instinct** | 跨项目 | "Vue3 项目：Always use FormWrapper pattern for complex forms" |

## 提炼逻辑

读取 `classification-report.yaml` 的 `personal_candidates` + 查询 `Knowledge Vault/Knowledge/` 中已有的 Instinct：

```
for each personal_candidate:
  1. 搜索 Knowledge Vault 中是否存在类似 Pattern
  2. 统计跨项目出现次数
  3. 出现 ≥2 次 → 提炼为 Instinct
  4. 出现 = 1 次 → 保留为 personal_candidate，等下次验证
```

## 输出：instincts.yaml

```yaml
# .project-knowledge/instincts.yaml
extracted_at: "2026-08-05T10:00:00Z"

instincts:
  - id: instinct.form-wrapper
    type: Always
    statement: "Vue3 项目：Always use FormWrapper pattern for complex forms"
    evidence:
      projects: [afc-newcore-web, bcapnext, crm-system]
      total_occurrences: 47
      consistency: 0.96  # 47/49 forms use it
    source_patterns:
      - pattern.form-wrapper (afc-newcore-web)
      - pattern.form-layout (bcapnext)
    promotion_ready: true
    suggested_playbook: "Form Development.md"

  - id: instinct.repository-pattern
    type: Prefer
    statement: "TypeScript 项目：Prefer Repository Pattern for data access"
    evidence:
      projects: [afc-newcore-web, crm-system]
      total_occurrences: 31
      consistency: 0.89
    promotion_ready: true
    suggested_playbook: "Data Access Patterns.md"

  - id: instinct.avoid-any
    type: Avoid
    statement: "TypeScript 项目：Avoid `any` type in production code"
    evidence:
      projects: [afc-newcore-web, bcapnext, crm-system]
      any_usage_rate: "3%-8%"
    promotion_ready: true

  - id: instinct.pending
    type: Prefer
    statement: "Monorepo 项目：Prefer pnpm over npm"
    evidence:
      projects: [afc-newcore-web]  # 仅 1 个项目
    promotion_ready: false  # 等下一个项目验证
```

## Integration

Phase 6 (Classifier) → Phase 6.5 (Instinct Extraction) → Delivery

Delivery 读取 `instincts.yaml`：
- `promotion_ready: true` → Reviewer 确认 → Promotion 到 Knowledge Vault
- `promotion_ready: false` → 保留为 personal_candidate，等待更多项目验证
