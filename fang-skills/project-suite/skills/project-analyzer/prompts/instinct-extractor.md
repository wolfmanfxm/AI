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

> 本阶段产出**单项目建议** `recommendations.md`——分析完本项目后，**根据项目自身现状**（反模式、风险、技术债、统计）直接给出的改进建议 + 依据。它**不依赖跨项目 Instinct**；Instinct 是独立的跨项目产物（用于 Vault promotion），若存在可作为「依据」的佐证，但不是前置条件。

| 产出 | 范围 | 性质 | 去向 |
|------|------|------|------|
| `instincts.yaml` | 跨项目 | 反复出现的规律（价值判断） | Promotion → Knowledge Vault |
| `recommendations.md` | 单项目 | 本项目现状 → 应然建议 | 留 `.project-knowledge/`，供本项目 generator/planner 消费 |

### 生成逻辑

从本项目的 extractor 产出（antipattern/risk/statistics）直接提炼建议：

```
for each 本项目反模式/风险/技术债:
  若该项是「新代码可避免的」改进方向:
    生成 recommendation:
      priority:      Always / Prefer / Avoid
      status_quo:    <本项目事实，如「N% 代码存在 X 反模式」「存在超长单文件」>
      recommendation: <应然，如「新代码避免 X」「新模块拆解超长文件」>
      basis:         <本项目统计/证据，如「<知识文件> 统计 N%」>
      instinct_ref:  <若 Knowledge Vault 有对应 Instinct 则标注佐证，否则留空>
```

### 输出：recommendations/ 目录

每条建议一个 `.md` 文件，frontmatter 含 `type: recommendation` + `statement`（供 Knowledge Resolver 的 Hydrate 读取）：

```markdown
<!-- .project-knowledge/recommendations/<建议-id>.md -->
---
type: recommendation
priority: Prefer
statement: "<应然建议一句话，如「新代码优先类型化」>"
summary: "<现状一句话 → 建议一句话>"
---

现状：<本项目事实，如「N% 代码存在 X 反模式」>
建议：<应然，如「新代码避免 X」>
依据：<本项目统计/证据路径>（跨项目 <instinct-id> 可佐证）
```

> 每条建议落一个文件（供 Compiler 索引进 `knowledge-index.json` → Resolver 分桶进 `context.recommendations[]`）。`recommendations/index.md` 聚合为人类可读表格（可选）。具体数值一律来自本项目分析结果，不写死示例数据。

### 关键约束

- **`recommendations.md` 是「建议」不是「规范」**——generator 用于新代码改进，但不得当 blocking constraint（那是 rules/ 的职责）。
- **只写「有依据」的建议**——每条 recommendation 必须能溯源到**本项目统计/证据**（status_quo 的 source）；跨项目 Instinct 是可选的佐证，不是必需。
- **不修改现状描述**——recommendations.md 单独存放，不混进 patterns/api/graph.json（事实与观点分层：现状描述在 patterns/api/graph，价值判断在 recommendations）。
