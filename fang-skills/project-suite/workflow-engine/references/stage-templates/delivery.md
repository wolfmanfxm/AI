# Stage Template: Delivery

> Engine 拥有。Skill 通过 `@engine: delivery` 引用，只需提供 Actions/Exit/Failure。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | Validation passed（无 CRITICAL 发现或已修复） |
| Input  | Execution 全部产出 + validation-report.md |
| Output | 最终产出写入目标路径 + state.json 更新 + timeline 追加 |
| Recovery | 读 manifest.json → 验证 completed → 若 state.json 缺失则重新写入 |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 本 Skill 的最终写入/同步步骤（如 Phase A-D、Vault sync） |
| **Exit**    | 交付完成条件（如 manifest.status = completed, Vault sync 验证通过） |
| **Failure** | 交付失败场景 + 处理（如 graph.json 生成失败 → grep 回退） |

## 示例：Analyzer 的 Delivery

```markdown
### Stage: Delivery
@engine: delivery

| Actions  | Phase A 强制刷新JSON → Phase B 状态初始化 → Phase C 差异化更新 → Phase D 质量验证 + Vault sync + CLAUDE.md + timeline |
| Exit     | manifest status = completed, Vault sync 验证通过（文件差 ≤3） |
| Failure  | graph.json 生成失败 → grep 回退; Vault 不可达 → 跳过并标注 |
```
