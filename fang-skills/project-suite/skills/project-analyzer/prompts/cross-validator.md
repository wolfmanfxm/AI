# Cross-Extractor Validator

> 不同 Extractor 产出的 Candidate 互相验证。发现矛盾 → 标注并降级 confidence。

## Cross-Check Matrix

| Pair | Check | Method |
|------|-------|--------|
| Pattern ↔ Principle | Pattern claims 是否与 Principle 的 Always/Avoid 一致？ | 若 Pattern 说 "Repository Pattern 广泛使用" 但 Principle 说 "Avoid Repository for simple CRUD" → 标注矛盾 |
| Decision ↔ Architecture | Decision 的 chosen option 是否在 Architecture 中有体现？ | 若 Decision 说 "拆 monorepo" 但 Architecture 的 modules 未反映 → 标注 gap |
| Glossary ↔ Pattern/API | Glossary 的术语是否在 Pattern/API 中真实出现？ | 若 Glossary 定义 "Settlement = 结算" 但代码中找不到 → 标注 orphan term |
| Risk ↔ AntiPattern | Risk 和 AntiPattern 是否从不同角度发现同一问题？ | 若 Risk 标记 "God Component: detail.vue" 且 AntiPattern 也标记 → 合并为一条，confidence 提升 |
| Convention ↔ Pattern | Convention 的规范是否与 Pattern 的统计一致？ | 若 Convention 说 "PascalCase 95%" 但 Pattern Extractor 的实际计数偏差 >10% → 标注 inconsistency |
| Framework ↔ Architecture | Framework 的技术栈是否与 Architecture 的分层一致？ | 若 Framework 说 "Vue 3.4 + Pinia" 但 Architecture 描述 "Vuex" → 标注矛盾 |
| Decision ↔ Principle | Decision 的选择是否违背了 Principle 的 Always/Never？ | 若 Principle 说 "Always use Composition API" 但 Decision 允许 Options API → 标注 trade-off |
| Directory ↔ Architecture | Directory 的模块列表是否与 Architecture 的模块描述一致？ | 若 Directory 列出 36 modules 但 Architecture 只描述 30 → 标注 missing modules |

## Actions

1. 读取所有 accepted candidates 的 evidence-format YAML
2. 按 Cross-Check Matrix 逐对验证
3. 发现矛盾：
   - 轻微 → 标注 `[CROSS-CHECK: minor inconsistency]`，不降 confidence
   - 中等 → 标注 `[CROSS-CHECK: conflict]`，双方 confidence -0.05
   - 严重 → 标注 `[CROSS-CHECK: contradiction]`，双方 confidence -0.15，标记需人工审核
4. 发现互补（同一问题从不同角度验证）→ 双方 confidence +0.03

## Output: cross-validation-report.yaml

```yaml
cross_validation:
  pairs_checked: 18
  conflicts_found: 2
  complements_found: 5

  conflicts:
    - pair: [convention.pascalcase, pattern.component-naming]
      severity: minor
      description: "Convention claims 95% PascalCase, Pattern counted 91%"
      resolution: "adjusted convention.pascalcase confidence 0.95 → 0.90"
    - pair: [decision.monorepo, architecture.modules]
      severity: medium
      description: "Decision chose monorepo split, but Architecture modules don't reflect workspace/ separation"
      resolution: "both confidence -0.05, flagged for human review"

  complements:
    - pair: [risk.god-component, antipattern.god-object]
      description: "Both identify detail.vue(1200行) as problematic from different angles"
      action: "merged into single knowledge object with confidence boost +0.03"
```

## Integration

Phase 2.5（Verifier 之后、Knowledge Builder 之前）执行 Cross-Validator。
