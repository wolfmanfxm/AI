# Promotion Reviewer Agent

> Phase 7.5 — Instinct Extraction 之后、Delivery 之前。
> 自动评分 personal_candidates → Promote/Keep/Reject。人工只 Review 边界案例。

## 评分维度

| 维度 | 权重 | 含义 | 高分条件 |
|------|------|------|---------|
| **CrossProject** | 35% | 跨项目适用性 | ≥2 个项目出现相同 pattern |
| **Reusability** | 30% | 可复用程度 | 可独立提取为 playbook/rule，不依赖项目上下文 |
| **FrameworkCoupling** | 20% | 框架耦合度 | 越低越好——框架无关的知识复用性最高 |
| **EvidenceStrength** | 15% | 证据强度 | occurrences ≥ 10 + consistency ≥ 0.9 |

## 评分规则

| Score | CrossProject | Reusability | FrameworkCoupling | Recommendation |
|-------|-------------|-------------|-------------------|----------------|
| 9-10 | ≥3 projects | 独立 playbook | 框架无关 | ✅ **Auto-Promote** |
| 7-8 | ≥2 projects | 可提取为 rule | 框架弱相关 | 🟡 **Promote Candidate** (人工确认) |
| 5-6 | 1 project + 强 pattern | 项目内可复用 | 框架相关 | 🔵 **Keep as Project** |
| <5 | 1 project + 弱 evidence | 项目特定 | 框架强绑定 | ⚪ **Reject** (保留为 project) |

## Output: promotion-review.yaml

```yaml
reviewed_at: "2026-08-05T12:00:00Z"
reviewer: promotion-reviewer-agent

scores:
  - candidate: pattern.form-wrapper
    cross_project: 0.87    # 出现在 acme-web + cms
    reusability: 0.93      # 可独立提取为 "Vue3 Form Pattern"
    framework_coupling: 0.18  # 框架弱相关（仅依赖 Vue3 + Element Plus）
    evidence_strength: 0.95  # 331 occurrences, consistency 0.96
    composite: 0.91
    recommendation: auto_promote
    reason: "≥2 projects, high reusability, low framework coupling"

  - candidate: convention.import-order
    cross_project: 0.45    # 仅 acme-web
    reusability: 0.60      # 项目特定 import 约定
    framework_coupling: 0.30
    evidence_strength: 0.70
    composite: 0.52
    recommendation: keep_project
    reason: "single project, medium reusability — keep as project convention"

  - candidate: pattern.legacy-api-wrapper
    cross_project: 0.10
    reusability: 0.20
    framework_coupling: 0.85  # 强绑定遗留系统
    evidence_strength: 0.40
    composite: 0.28
    recommendation: reject
    reason: "legacy-specific, high coupling, low reusability"

summary:
  auto_promote: 1
  promote_candidate: 0
  keep_project: 1
  reject: 1
```

## 人工 Review 边界

`recommendation` 是**评分建议**，不是自动执行。Personal 晋升（跨项目写入 Vault）是长期资产，**无论 auto_promote 还是 promote_candidate，都需人工确认后才晋升**：

- `auto_promote`（≥9 分）→ 强烈建议晋升，但仍是建议，等人工确认
- `promote_candidate`（7-8 分）→ 建议晋升，人工确认
- `keep_project` / `reject` → 项目内保留 / 拒绝，不涉及跨项目晋升

统一模型（见 [promotion-rules.md](../../../runtime/state/schemas/promotion-rules.md)）：

```
Candidate → Background Reviewer 评分 → Promote/Keep/Reject 建议 → [人工确认] → Vault
```

Background 只产建议（auto-score/auto-classify/auto-suggest），Personal promotion 的最终动作是 human confirmation。
