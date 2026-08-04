# Approval Framework v1.0

> CHECKPOINT 是审批点。本框架定义审批级别、日志格式和审计追踪。
> yao-meta-skill Governed 模式要求。

## 审批级别

| Level | Trigger | Action | Logged? |
|-------|---------|--------|---------|
| **AUTO_PASS** | confidence ≥ `interface.quality_gate.min_confidence_for_pass` | 无需人工确认，直接进入下一阶段 | ✅ 自动记录 |
| **CHECKPOINT** | 所有 Stage 边界 | `AskUserQuestion` — 用户选"继续"/"调整"/"取消" | ✅ 用户选择写入 approval_log |
| **GATE** | confidence < `interface.quality_gate.requires_review_below` | 强制 Review 后才能继续 | ✅ GATE 触发记录 |
| **BLOCK** | confidence < `interface.quality_gate.blocks_downstream_below` | 拒绝下游执行 | ✅ BLOCK 原因记录 |
| **MANUAL_OVERRIDE** | 用户主动覆盖 GATE/BLOCK | AskUserQuestion 确认覆盖 | ✅ 覆盖理由记录 |

## 审批日志格式

每次审批决策写入 `state.json` 的 `approval_log` 数组：

```json
{
  "approval_log": [
    {
      "timestamp": "2026-08-04T15:30:00Z",
      "skill": "project-analyzer",
      "stage": "discovery",
      "level": "CHECKPOINT",
      "decision": "continue",
      "confidence_at_decision": 90,
      "user_override": false,
      "reason": ""
    }
  ]
}
```

## 审计追踪

`shared/scripts/check-approval-audit.sh` 验证：

| Check | Rule |
|-------|------|
| Stage 完整性 | 每个 stage 有对应 CHECKPOINT 记录 |
| GATE 合规 | confidence < requires_review_below → 必须有 Review 记录或 MANUAL_OVERRIDE |
| BLOCK 合规 | confidence < blocks_downstream_below → 必须被 MANUAL_OVERRIDE 覆盖，不能跳过 |
| 覆盖理由 | MANUAL_OVERRIDE 必须有非空的 reason 字段 |

## 审批流

```
Stage: Discovery
  │
  ├─→ confidence ≥ 90 → AUTO_PASS → 进入 Execution
  ├─→ confidence 70-89 → CHECKPOINT → 用户选择
  └─→ confidence < 70 → GATE → 强制 Review 或 MANUAL_OVERRIDE

Stage: Execution
  │
  ├─→ confidence ≥ 95 → AUTO_PASS → 进入 Validation
  ├─→ confidence 70-94 → CHECKPOINT → 用户选择
  └─→ confidence < 70 → GATE

Stage: Validation
  │
  ├─→ PASS → AUTO_PASS → 进入 Delivery
  ├─→ NEEDS_FIX → CHECKPOINT → 用户选择"修复"/"记录后继续"
  └─→ BLOCKED → BLOCK → 必须修复
```
