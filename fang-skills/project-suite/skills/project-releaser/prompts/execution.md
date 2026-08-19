# Execution — Releaser

> @template: execution

## Actions

### 0. 全链路 Confidence Gate

→ [confidence-gate](../../../runtime/mechanisms/confidence-gate.md)

扫描 `state.json` history：
- 任一上游 confidence <40 → 🔴 BLOCK，拒绝发布
- 任一上游 confidence <70 → 🟠 GATE，AskUserQuestion 确认
- 全部 ≥90 → 🟢 PASS，正常发布

### 1. 版本号推荐

按 conventional commits 推算：
- breaking change 存在 → **MAJOR**
- feat 存在且无 breaking → **MINOR**
- 仅 fix/refactor/docs → **PATCH**

### 2. Changelog 合成

→ [prompts/changelog-gen.md](changelog-gen.md)

输入：`@adapter:git.log` + PR 描述 + REVIEW.md（若存在）
输出：按版本分组的 CHANGELOG.md（Added/Changed/Fixed/Deprecated/Removed）

### 3. 发布检查清单

→ [prompts/release-checklist.md](release-checklist.md)

逐项验证：
- 测试通过
- 文档更新
- BREAKING CHANGE 有迁移说明（旧API→新API）
- 回滚方案完整（git revert 命令 + 验证步骤）

🔴 CHECKPOINT — 展示版本号建议 + Changelog 摘要 + 检查清单结果

## Exit

- 全链路 confidence 检查通过（或用户已覆盖 GATE）
- 版本号已推荐
- Changelog 已生成
- 检查清单已完成
- 用户已确认

## Failure

| Condition | Action |
|-----------|--------|
| 全链路 confidence<40 | 🔴 BLOCK — 拒绝生成发布产物 |
| breaking change 无迁移说明 | 在 CHANGELOG 显式标注 BREAKING CHANGE + 自动生成迁移步骤草案 |
| CHANGELOG.md 不存在 | 从 git log 生成全新 CHANGELOG.md → 标注 `⚠️ 首次生成，请人工审核` |
