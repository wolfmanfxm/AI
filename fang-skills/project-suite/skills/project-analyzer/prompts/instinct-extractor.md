# Instinct Extractor

> Phase 6.5 — Classifier 之后、Delivery 之前。
> 从跨项目 personal_candidates 中提炼 Instinct（Always/Prefer/Avoid/Never）。

## 什么是 Instinct

Instinct 不是单个项目的 Pattern，而是**跨项目反复出现的规律**。

| 层级 | 范围 | 示例 |
|------|------|------|
| **Fact** | 单项目 | "acme 用 <统一表单封装> 封装表单" |
| **Rule** | 单项目 | "acme 所有表单必须用 <统一表单封装>" |
| **Instinct** | 跨项目 | "Vue3 项目：Always use <统一表单封装> pattern for complex forms" |

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
    statement: "Vue3 项目：Always use <统一表单封装> pattern for complex forms"
    evidence:
      projects: [acme-web, cms, crm-system]
      total_occurrences: 47
      consistency: 0.96  # 47/49 forms use it
    source_patterns:
      - pattern.form-wrapper (acme-web)
      - pattern.form-layout (cms)
    promotion_ready: true
    suggested_playbook: "Form Development.md"

  - id: instinct.repository-pattern
    type: Prefer
    statement: "TypeScript 项目：Prefer Repository Pattern for data access"
    evidence:
      projects: [acme-web, crm-system]
      total_occurrences: 31
      consistency: 0.89
    promotion_ready: true
    suggested_playbook: "Data Access Patterns.md"

  - id: instinct.avoid-any
    type: Avoid
    statement: "TypeScript 项目：Avoid `any` type in production code"
    evidence:
      projects: [acme-web, cms, crm-system]
      any_usage_rate: "3%-8%"
    promotion_ready: true

  - id: instinct.pending
    type: Prefer
    statement: "Monorepo 项目：Prefer pnpm over npm"
    evidence:
      projects: [acme-web]  # 仅 1 个项目
    promotion_ready: false  # 等下一个项目验证
```

## Integration

Phase 6 (Classifier) → Phase 6.5 (Instinct Extraction) → Delivery

Delivery 读取 `instincts.yaml`：
- `promotion_ready: true` → Reviewer 确认 → Promotion 到 Knowledge Vault
- `promotion_ready: false` → 保留为 personal_candidate，等待更多项目验证

---

## 项目建议（单项目应然，区别于 cross-project Instinct）

> 除跨项目 Instinct 外，本阶段还产出**单项目建议** `recommendations.md`——把跨项目 Instinct 应用到「这个项目」的现状，生成项目级改进建议。与 `instincts.yaml` 的区别：

| 产出 | 范围 | 性质 | 去向 |
|------|------|------|------|
| `instincts.yaml` | 跨项目 | 反复出现的规律（价值判断） | Promotion → Knowledge Vault |
| `recommendations.md` | 单项目 | 本项目现状 → 应然建议 | 留 `.project-knowledge/`，供本项目 generator/planner 消费 |

### 生成逻辑

对每条 `promotion_ready: true` 的 Instinct，检查本项目现状是否命中：

```
for each instinct in instincts.yaml:
  if instinct 的 evidence（any_usage_rate / consistency / occurrences）与本项目 facts 匹配:
    生成 recommendation:
      priority:     instinct.type（Always/Prefer/Avoid）
      status_quo:   <本项目事实，如「存量 API 大量返回 any」>
      recommendation: <应然，如「新代码优先类型化泛型 IResponseResultRows<T>」>
      basis:        <instinct.id + evidence>
      source:       <本项目知识文件路径，如 api/overview.md>
```

### 输出：recommendations.md

```markdown
---
type: recommendation
scope: project
---
# 项目建议（应然，非现状规范）

> ⚠️ 本文档是「建议/推荐」——针对**未来新代码**的改进方向，不是对现状的准确描述。
> 现状见 patterns/、api/、graph.json。冲突时：**新代码遵循「建议」，理解存量代码看「现状」**。

| 优先级 | 现状（事实） | 建议（应然） | 依据 |
|--------|-------------|-------------|------|
| Prefer | 存量 API 大量返回 `Promise<AxiosResponse<any>>` | 新代码优先类型化泛型 `IResponseResultRows<T>` | instinct.avoid-any（any_usage_rate 超标） |
| Avoid | 存在超大单文件（God Component） | 新模块避免 500+ 行单文件，拆 composition | instinct.split-god-component |
```

### 关键约束

- **`recommendations.md` 是「建议」不是「规范」**——generator 用于新代码改进，但不得当 blocking constraint（那是 rules/ 的职责）。
- **只写「有依据」的建议**——每条 recommendation 必须能溯源到 Instinct（basis）或本项目统计（status_quo 的 source），不能凭空提建议。
- **不修改现状描述**——recommendations.md 单独存放，不混进 patterns/api/graph.json（事实与观点分层：现状描述在 patterns/api/graph，价值判断在 recommendations）。
