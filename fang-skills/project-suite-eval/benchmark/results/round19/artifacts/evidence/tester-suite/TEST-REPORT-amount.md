# TEST-REPORT — formatAmount / AC '.5' → '0.5'

- 被测: project/src/utils/amount.ts:6 `formatAmount`
- 框架: ⚠️ 未检测到（无 package.json/node_modules）→ 使用 Node v24 内置 `node:test` + `node:assert/strict`
- 测试文件: /tmp/ps-eval-run19-tester/amount.test.mjs（未写入 project/src）
- 执行: `node --test --test-reporter=spec amount.test.mjs`
- 结果: 9 tests, 6 pass, 3 fail, 0 skip

## AC 对照
| AC | 用例 | 预期 | 实际 | 结论 |
|----|------|------|------|------|
| '.5' → '0.5' | 应该把 ".5" 格式化为 "0.5" | 0.5 | .5 | [RED 证据] |

## 失败分类（V6）
- [RED 证据] `.5` → 实际 `'.5'`，期望 `'0.5'`（对应唯一 AC）
- [RED 证据] `-.5` → `'-.5'`，期望 `'-0.5'`（同一 AC 家族：小数以 0 开头；amount.ts:59-61 仅补负号）
- [RED 证据] `.75` → `'.75'`，期望 `'0.75'`（同一 AC 家族）
- 环境错误: 0

## 根因定位（只读，不修复）
amount.ts:51 前导零处理仅在 `clean.startsWith('0')` 时触发；以 `.` 开头的 clean 不进入该分支，amount.ts:63 直接返回 `.5`。缺「`.` 开头时补 `0`」分支。负数同样受影响（amount.ts:37 去负号、amount.ts:61 补回）。

## Validation
- V1 AC 覆盖 ✅ | V2 边界 null/undefined/''/超长 ✅ | V3 可执行 ✅
- V4 未篡改源码 ✅（仅创建 /tmp 下测试文件） | V5 覆盖率基线 ⚠️ 无基线
- V6 失败已分类 ✅

## 供修复后复核
修复后重跑同一文件，AC 用例应由 RED 转绿。
