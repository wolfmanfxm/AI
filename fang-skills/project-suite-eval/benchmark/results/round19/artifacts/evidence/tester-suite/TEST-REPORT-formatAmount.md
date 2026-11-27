# TEST-REPORT — formatAmount（AC: '.5' → '0.5'）

- 被测：`project/src/utils/amount.ts:6` `formatAmount`
- 测试框架：⚠️ 未检测到（夹具无 `package.json` / `node_modules`，jest/vitest 不可用）
  → 兜底采用 Node v24.15.0 内置 `node:test` + `node:assert/strict`，`describe/it` 结构
- 测试文件：`/tmp/ps-eval-run19-tester/amount-ac.test.mjs`（未写入 project/src）
- 执行命令：`node --test --test-reporter=spec amount-ac.test.mjs`
- 结果：**10 tests / 6 pass / 4 fail / 0 skip**

## AC → 用例映射（V1）

| AC | 用例 | 预期 | 实际 | 结论 |
|----|------|------|------|------|
| '.5' 必须返回 '0.5'（小数以 0 开头） | `AC: ".5" -> "0.5"` | `'0.5'` | `'.5'` | **[RED 证据]** |

同族规则（同一 AC：「小数必须以 0 开头」的负数/多位小数分支）一并覆盖，共 3 条失败：

| 输入 | 预期 | 实际 |
|------|------|------|
| `-.5` | `-0.5` | `-.5` |
| `.75` | `0.75` | `.75` |
| `.567` | `0.56` | `.56` |

## 边界/异常覆盖（V2，全部通过）

`null` / `undefined` / `''` → `''`；`'0.5'` 原样；`'007'` → `'7'`；超长数字串不截断。

## 失败分类（V6）

| 类型 | 数量 | 说明 |
|------|------|------|
| [RED 证据] | 4 | 目标行为未满足，可复现；非环境问题 |
| [潜在Bug] | 0 | 无越界崩溃 |
| 环境错误 | 0 | — |

**根因（只读定位，不修复）**：`amount.ts:51` 的补 0 分支条件是 `clean.startsWith('0')`，以 `.` 开头的 `clean` 永不进入，`amount.ts:63` 直接返回 `.5`。缺少「以 `.` 开头时前置补 `0`」分支；负数走 `amount.ts:37/61`，同样未补 0。

## Validation 核对

- V1 AC 覆盖 ✅（1 条 AC + 同族 3 条）
- V2 边界 ✅
- V3 可执行 ✅（node --test 无语法/配置错误）
- V4 未篡改源码 ✅（仅 `ls`/`cat`/`node --test`，写入仅在 /tmp）
- V5 覆盖率基线 ⚠️ 无基线（无框架，未生成 lcov）
- V6 失败已分类 ✅

## 交付与复核

修复 `amount.ts` 后重跑同一命令，4 条 RED 用例应转绿；其余 6 条为回归护栏，须保持通过。
