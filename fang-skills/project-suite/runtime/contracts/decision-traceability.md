# Decision Traceability v1.0

> 跨 Artifact 的 ID 追踪。让 Reviewer 能验证完整决策链，而非只看单个 Artifact。
> 从 Artifact-driven 升级为 Decision-traceable。

## ID 规范

| 前缀 | 含义 | 产生于 | 示例 |
|------|------|--------|------|
| `R-` | Requirement | Interview / Requirement Spec | R-007 |
| `D-` | Decision | Planner | D-003 |
| `T-` | Task | Planner | T-012 |
| `ADR-` | Architecture Decision | Architect | ADR-004 |
| `AC-` | Acceptance Criteria | Planner | AC-006 |
| `F-` | Review Finding | Reviewer | F-002 |

格式：`<PREFIX>-<3位数字>`（R-007, T-012）。

## 追踪链

```
R-007 (Requirement: 支持头像上传)
  ↓ satisfies
T-012 (Task: 实现头像上传组件)
  ↓ implements
ADR-004 (Architecture: 头像用 BigFileUpload)
  ↓ realized_in
code (实现代码)
  ↓ verified_by
AC-006 (Acceptance: 头像上传成功显示预览)
  ↓ covered_by
test (测试用例)
```

## 关联字段

每个 Artifact 声明上游 ID：

```yaml
# PLAN.md 的 Task 条目
- id: T-012
  satisfies: R-007          # 追溯 requirement
  decision: D-003            # 关联 decision

# ARCHITECTURE.md 的 ADR 条目
- id: ADR-004
  implements: D-003          # 追溯 planner decision

# AC 条目
- id: AC-006
  verifies: T-012            # 验证哪个 task
```

## Reviewer 验证（check-artifacts.sh 的 ID Traceability 段）

每个 ID 必须能被追溯到上游，不能是孤立的：

| 检查 | 规则 |
|------|------|
| T → R | 每个 Task 的 `satisfies` 指向存在的 Requirement |
| ADR → D | 每个 Architecture Decision 的 `implements` 指向存在的 Decision |
| AC → T | 每个 Acceptance Criteria 的 `verifies` 指向存在的 Task |
| F → AC | 每个 Review Finding 的 `against` 指向存在的 AC |

孤立 ID（无上游追溯）→ ⚠️ Drift。
