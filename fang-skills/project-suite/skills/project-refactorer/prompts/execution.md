# Execution — Refactorer

> @template: execution

## Actions

小步循环：

```
循环直到目标达成:
  1. 跑现有测试 → 确认全绿（不绿则停止，先修测试）`@adapter:execution.run "npm test"`
  2. 做 1 个重构动作（提取/内联/重命名/简化条件/...）
  3. 跑测试 → 仍绿 → 记录 before/after 到 REFACTOR.md
  4. 测试变红 → Edit 反向回滚 → 分析原因 → 记录 REFACTOR.md → 继续下一个动作
```

### 重构手法（9种）

→ [prompts/extract-method.md](extract-method.md) / [prompts/simplify-logic.md](simplify-logic.md) 等

### 安全协议

→ [references/safety-protocol.md](../references/safety-protocol.md)：
- 每次只改 1-2 文件
- 重构和功能变更分开 commit
- 每步改动后验证测试全绿

🔴 CHECKPOINT — 展示重构摘要（改动文件数 + Before→After 指标 + 测试结果）

## Exit

- 目标达成（坏味道已消除或显著改善）
- 所有测试保持绿色
- 每个重构动作独立记录（可单独回滚）

## Failure

| Condition | Action |
|-----------|--------|
| 重构后测试变红 | 逐段对比 before/after → 定位原因 → 无法定位则用 `Edit` 反向回滚整个重构改动 |
| 范围过大（>5 文件） | 拆分为多次小重构，每次 1-2 文件 → AskUserQuestion 确认是否一次性 |
| 改善不明显（<20%） | 尝试更激进手法（提取策略模式、引入多态）→ 标注 `⚠️ 边际改善` |
