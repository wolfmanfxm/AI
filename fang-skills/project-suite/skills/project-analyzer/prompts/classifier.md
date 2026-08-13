# Knowledge Classifier

> Phase 6 — Knowledge Builder + INDEX 之后、Delivery 之前。
> 对每个 Knowledge Object 分配 promotion level，决定同步策略。

## Promotion Levels

| Level | 含义 | 同步到 | 示例 |
|-------|------|--------|------|
| **`none`** | 一次性任务产物 | 仅 `.project-knowledge/`，归档 | PLAN-*.md, REVIEW-*.md, CHANGELOG-*.md, TEST-REPORT.md, REFACTOR.md, ARCHITECTURE-<feature>.md |
| **`project`** | 长期项目知识 | → `Knowledge Vault/Projects/{project}/` | architecture/overview.md, components/catalog.md, patterns/repository.md, conventions/naming.md, glossary.md, principles.md, risks.md, rules/, experience/ |
| **`personal`** | 跨项目通用 | → `Knowledge Vault/Knowledge/` | 通用 Pattern（如 "Form Design with Schema Validation"）、通用 Playbook（如 "Microservice Migration Pattern"） |

## 分类规则

### 自动分类（按文件名/目录）

| 匹配 | Promotion | 原因 |
|-------|----------|------|
| `proposals/PLAN-*.md` | `none` | 一次性任务规划 |
| `reports/REVIEW-*.md` `CHANGELOG-*.md` `TEST-REPORT.md` `REFACTOR.md` | `none` | 一次性任务产出 |
| `decisions/ARCHITECTURE-<feature>.md` | `none` | 单功能架构决策 |
| `candidates/` | `none` | 中间产物 |
| `architecture/` `components/` `api/` | `project` | 项目结构知识 |
| `patterns/` `conventions/` `observations/` | `project` | 项目模式与规范 |
| `glossary.md` `INDEX.md` `knowledge-graph.yaml` | `project` | 项目知识索引 |
| `context.json` `graph.json` `statistics.json` | `project` | 结构化项目数据 |
| `decisions/architecture-decisions.md` `decisions/index.md` | `project` | 项目级决策标准 |
| `reports/latest.md` | `project` | 项目变更历史 |
| `rules/` | `project` | 视情况晋升 personal |
| `experience/` | `personal`（review.status=pending） | 候选：由 Promotion Reviewer 语义判断（跨项目? framework-independent? evidence≥N? 复用?）→ Promote 才真进 personal |
| `playbooks/` | `personal`（review.status=pending） | 候选：同上 |
| Best Practices（通用最佳实践） | `personal`（review.status=pending） | 候选：同上 |
| Framework-agnostic Principles | `personal`（review.status=pending） | 候选：同上 |

### 与同步矩阵对照

```
promotion:none     → .project-knowledge/ 仅保留本地
promotion:project  → + Vault/Projects/<项目>/  自动同步
promotion:personal → + Vault/Knowledge/        Reviewer确认后晋升
```

| Analyzer 产物 | none | project | personal |
|--------------|------|---------|----------|
| PLAN | ✅ | — | — |
| Task Architecture | ✅ | — | — |
| Review | ✅ | — | — |
| QA / Checklist | ✅ | — | — |
| Components | — | ✅ | — |
| Architecture | — | ✅ | — |
| Decisions(项目级) | — | ✅ | — |
| Rules | — | ✅ | 视情况 |
| Patterns | — | ✅ | 视情况 |
| Glossary | — | ✅ | 一般不 |
| Experience | — | ✅ | ✅推荐 |
| Best Practices | — | ✅ | ✅ |
| Playbooks | — | ✅ | ✅ |
| Framework-agnostic Principles | — | ✅ | ✅ |

### 手动 Promotion（需 Reviewer 确认）

跨项目价值的知识 → 标记为 `personal` 候选，Reviewer 确认后提升。

## Output: classification-report.yaml

```yaml
# .project-knowledge/classification-report.yaml
classified_at: "2026-08-05T10:00:00Z"
classifier: knowledge-classifier

classified:
  none:
    - proposals/PLAN-quota-v1.1.md
    - reports/REVIEW-quota-v1.1.md
    - decisions/ARCHITECTURE-quota-wholesale-gap.md
  project:
    - architecture/overview.md
    - components/catalog.md
    - patterns/repository.md
    - conventions/naming.md
    - glossary.md
    - principles.md
    - decisions/architecture-decisions.md
  personal_candidates:
    - { id: pattern.form-schema-validation, reason: "跨项目通用: 所有表单统一使用 Schema Validation 模式", confidence: 0.85 }

sync_actions:
  - action: archive
    files: [proposals/PLAN-*.md, reports/REVIEW-*.md, ...]
    target: .project-knowledge/ (仅保留本地)
  - action: project_sync
    files: [architecture/, components/, patterns/, ...]
    target: Knowledge Vault/Projects/{project}/
  - action: promotion_review
    files: [pattern.form-schema-validation]
    target: Knowledge Vault/Knowledge/Patterns/ (待 Reviewer 确认)

# Delivery 阶段读取此文件，按 promotion level 执行同步
```

## Integration

Phase 5（Knowledge Builder 之后、Delivery 之前）执行。
自动分类 → 输出 classification-report.yaml → Delivery 据此同步。
