# Discovery — Tester

> @engine: discovery

## Actions

1. 读 `PLAN.md > # Acceptance Criteria` → 提取每条 AC 为测试目标
2. 检测测试框架：扫描 `package.json` devDependencies（jest/vitest/mocha/playwright）
3. 定位测试目录和命名约定：`__tests__/` / `*.test.ts` / `*.spec.ts`
4. CHECKPOINT — 展示测试策略（框架/目录/命名/AC→用例映射）

## Exit

- 测试框架已确定
- 测试目录和命名约定已确定
- AC→用例映射已建立
- 用户确认测试策略

## Failure

| Condition | Action |
|-----------|--------|
| 检测不到测试框架 | 扫描 `package.json` devDependencies → 默认 jest 风格，标注 `⚠️ 未检测到框架` |
| 被测代码不可读或不存在 | 🔴 BLOCKED — 提示用户确认文件路径 |

## CHECKPOINT

🔴 CHECKPOINT
