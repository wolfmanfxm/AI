<!-- arm=tester-r1 session=c1ce9c42-5851-4df8-91b7-1c721a974ecb turns=17 subagents=0 -->
Skill 调用: 成功（project-tester）

**测试策略**（无人交互，按 skill 默认自主执行）
- 框架：⚠️ 未检测到（无 package.json/node_modules）→ Node v24 内置 `node:test`，直接 import 被测 `.ts`
- 目录/命名：`/tmp/ps-eval-run19-tester/amount.test.mjs`（未写入 project/src）
- AC→用例：1 条 AC → `.5` 必测；同族补 `-.5`、`.75`；边界补 null/undefined/''/超长；回归补 `0.5`、`007`

**执行结果**：9 tests，6 pass / 3 fail / 0 skip（`node --test --test-reporter=spec amount.test.mjs`）

| AC | 预期 | 实际 | 判定 |
|---|---|---|---|
| `.5`→`0.5` | `0.5` | `.5` | **[RED 证据]** |
| `-.5`→`-0.5` | `-0.5` | `-.5` | [RED 证据] |
| `.75`→`0.75` | `0.75` | `.75` | [RED 证据] |

**根因（只读，未改源码）**：`amount.ts:51` 前导零处理仅在 `startsWith('0')` 时触发，以 `.` 开头不进入；`:63` 直接返回 `.5`。负数经 `:37`/`:61` 同样受影响。

**Validation**：V1 AC 覆盖 ✅｜V2 边界 ✅｜V3 可执行 ✅｜V4 未篡改源码 ✅｜V5 ⚠️ 无覆盖率基线｜V6 失败已分类 ✅。报告：`/tmp/ps-eval-run19-tester/TEST-REPORT-amount.md`。未修复被测代码——待修复后用同一用例复核转绿。

```js
import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '/Users/fangxiangming/.cache/ps-eval/round19/tester/project/src/utils/amount.ts'

describe('formatAmount', () => {
  test('应该把 ".5" 格式化为 "0.5"', () => {          // AC
    assert.equal(formatAmount('.5'), '0.5')
  })
  test('应该把 "-.5" 格式化为 "-0.5"', () => {
    assert.equal(formatAmount('-.5'), '-0.5')
  })
  test('应该把 ".75" 格式化为 "0.75"', () => {
    assert.equal(formatAmount('.75'), '0.75')
  })
  test('null 应返回空字符串', () => assert.equal(formatAmount(null), ''))
  test('undefined 应返回空字符串', () => assert.equal(formatAmount(undefined), ''))
  test('空字符串应返回空字符串', () => assert.equal(formatAmount(''), ''))
  test('超长数字字符串应原样保留', () => assert.equal(formatAmount('12345678901234567890'), '12345678901234567890'))
  test('应该保留 "0.5" 不变', () => assert.equal(formatAmount('0.5'), '0.5'))
  test('应该把 "007" 规范为 "7"', () => assert.equal(formatAmount('007'), '7'))
})
```
