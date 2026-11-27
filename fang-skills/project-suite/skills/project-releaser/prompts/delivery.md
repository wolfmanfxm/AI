# Delivery — Releaser

> @template: delivery

## Actions

写入 `.project-knowledge/reports/` 下（**不在项目根目录**）：
1. `CHANGELOG.md` — 按版本分组（Added/Changed/Fixed/Deprecated/Removed）
2. `RELEASE-CHECKLIST.md` — 逐项检查结果 + 回滚方案；**并附交付实证**（按 [Delivery Evidence 原语](../../../shared/primitives/delivery-evidence.md)）：每个关键变更给改前/改后证明对（Before: 具体失败测试/错误 → After: 通过）+ Merge Danger（Door: one-way/two-way + Blast Radius，用 reviewer findConsumers 依据）。
   **one-way / 高风险变更必须再给两段**：`Safety Invariant`（安全所依赖的关键事实）+ `Proof`（实际执行的同一命令/场景：改前失败 → 改后通过）。没真跑就写 `UNPROVEN` + 原因，**单独列出、不参与 PASS 计数**——不得用推理代替。two-way 小改动不加这两段（避免套话化）。one-way door（destructive/schema/API 契约）显式标注 + 迁移步骤。
3. 版本号推荐 — semver 版本号 + 推荐理由（呈现在报告里，不单独落文件）

**不执行** `npm publish` / `git push --tags` — 这些由人工执行。

## Exit

- `CHANGELOG.md` 写入成功
- `RELEASE-CHECKLIST.md` 写入成功
- 版本号推荐已呈现
- 提交 State 更新建议（Dispatcher 统一提交根 state.json）

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
