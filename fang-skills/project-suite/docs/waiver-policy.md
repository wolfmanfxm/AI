# Waiver Policy v1.0

> 当 Gate 被有意跳过时的追踪机制。yao-meta-skill Governed 模式要求。

## 何时需要 Waiver

| 场景 | 示例 |
|------|------|
| **G3 豁免** | 某 Skill 的边界极其明确，不需要 3 条反例 |
| **G10 豁免** | Skill 确实与特定 platform 绑定（如 `在 Claude Code` 是合理的上下文） |
| **G17 豁免** | Skill 已稳定 >1 年，审查周期延长到 180 天 |
| **Confidence 豁免** | 用户确认已知风险后继续，跳过 GATE |

## Waiver 格式

在 `skill.yaml` 中声明：

```yaml
waivers:
  - gate: G3
    reason: "analyzer 的反例在 boundary.md 中只有 2 条，第 3 条在 SKILL.md 反例表中"
    expires: "2026-11-04"
    approved_by: "dispatcher"
  - gate: G17
    reason: "该 Skill 已稳定运行 1 年，审查周期延长"
    expires: "2027-02-04"
    approved_by: "dispatcher"
```

## Waiver 规则

| Rule | Detail |
|------|--------|
| **过期** | 每个 waiver 必须有 `expires` 日期，过期后 Gate 恢复 |
| **审批** | `approved_by` 记录审批人 |
| **可见** | conformance checker 显示活跃 waivers 数量 |
| **不可堆叠** | 同一 Gate 不能有多个活跃 waiver |

## Conformance Checker 集成

`check-conformance.sh` 遇到 WARNING 时，检查该 Skill 是否有对应 Gate 的活跃 waiver：
- 有 + 未过期 → `✅ Gx WAIVED (expires: <date>)`
- 有 + 已过期 → `❌ Gx WAIVER EXPIRED — must be renewed or fixed`
- 无 → 正常 WARNING
