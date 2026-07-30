# Confidence Gate v1.0.0

> 置信度驱动的自动化门禁。Skill 输出的 confidence 不再只是"建议"——Runtime 根据置信度自动决定：直通 / 建议Review / 阻断下游。

## 三级 Gate

```
confidence ≥ 90  →  🟢 PASS       直接进入下游，无需 Review
confidence 70-89 →  🟡 REVIEW     建议人工 Review 后再进入下游
confidence 40-69 →  🟠 GATE       强制 Review，禁止进入 Release
confidence < 40   →  🔴 BLOCK      阻断，必须重做或人工介入
```

## Gate 行为表

| Gate | 触发条件 | 对下游 Skill 的影响 | 用户操作 |
|------|---------|-------------------|---------|
| 🟢 PASS | confidence ≥ 90 | 正常执行，无额外检查 | 无需操作 |
| 🟡 REVIEW | 70 ≤ confidence < 90 | 建议先 Review，但不阻断 | 可选择跳过（标注风险） |
| 🟠 GATE | 40 ≤ confidence < 70 | Reviewer 强制检查后才能进 Generator；禁止进入 Releaser | 必须 Review 或重做上游 |
| 🔴 BLOCK | confidence < 40 | 拒绝执行下游，state.json 写入 blocker | 必须重做上游或人工介入 |

## 各 Skill 的 Gate 位置

```
analyzer（confidence ≥ 70 才能进 downstream）
  │
planner（confidence < 40 → 拒绝产出完整 PLAN）
  │
architect（confidence < 70 → 标注 ⚠️，建议 Review）
  │
generator（confidence < 70 → 🟠 GATE，必须 Review；confidence ≥ 95 → 🟢 直通）
  │
tester（confidence < 70 → 测试报告标注 ⚠️）
  │
reviewer（自身不受 gate，但检查上游 confidence）
  │
refactorer（confidence < 70 → 无测试保护不重构）
  │
documenter（confidence < 60 → 标注推断项）
  │
releaser（检查全链路：任一上游 confidence < 70 → 🟠 GATE 禁止发布）
```

## 全链路 Gate 检查（Releaser 专属）

Releaser 执行前扫描 state.json 全链路 confidence：

```
for each skill in history:
  if skill.confidence < 40:
    → 🔴 BLOCK release，提示重做
  if skill.confidence < 70:
    → 🟠 GATE release，列出低置信度环节，AskUserQuestion
  if skill.confidence < 90:
    → 🟡 标注 CHANGELOG "⚠️ 部分环节置信度 < 90"

all skill.confidence ≥ 90:
  → 🟢 PASS，正常发布
```

## state.json 集成

state.json 中每个 history 条目已含 `confidence` 字段：

```json
{
  "history": [
    {
      "skill": "project-generator",
      "status": "completed",
      "confidence": 65,
      "gate": "GATE",
      "gate_reason": "generator confidence < 70, Review required before proceeding"
    }
  ],
  "blockers": [
    {
      "type": "confidence_gate",
      "skill": "project-generator",
      "confidence": 65,
      "action_required": "Review before entering tester/releaser"
    }
  ]
}
```

**新字段：**
| 字段 | 说明 |
|------|------|
| `history[].gate` | PASS / REVIEW / GATE / BLOCK（由 Runtime 计算） |
| `history[].gate_reason` | 人类可读的 gate 原因 |
| `blockers[type=confidence_gate]` | confidence 不达标时写入 blocker |

## 用户覆盖

Confidence Gate 不是死规则。用户（Dispatcher）拥有最终决定权：

```
🟡 REVIEW / 🟠 GATE 触发时：
  → AskUserQuestion: "上游 confidence={N}，建议 Review。是否继续？"
  → 用户选"继续" → 标注 overridden_by=user，下游正常执行
  → 用户选"Review" → 执行 /project-reviewer

🔴 BLOCK 触发时：
  → 不提供"跳过"选项
  → 只提供：重做上游 / 人工介入修改
```

## 与现有 Confidence 体系的兼容

skill-io.md 已定义 Confidence 计算规则：

```
confidence = 100
- 20 if 输入信息模糊/不完整
- 15 if 依赖的 knowledge 状态非 accepted
- 15 if 依赖的上游产出置信度 < 70
- 10 if 遇到未预见的边界条件
- 10 if 使用了降级/fallback 模式
- 5  per 未验证假设（max -20）
```

本 Gate 协议在此之上增加**消费端行为**——以前 confidence 只是数字，现在决定下游能不能执行。
