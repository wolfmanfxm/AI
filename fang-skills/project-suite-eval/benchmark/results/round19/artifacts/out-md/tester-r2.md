<!-- arm=tester-r2 session=3acc67a8-70b3-492e-96e8-6fc9ceff77db turns=18 subagents=0 -->
`Skill 调用: 成功（project-tester）`

## 测试报告 — formatAmount / AC: `'.5'` → `'0.5'`

**Discovery**（只读；处于无人交互场景，因此按检测结果继续执行）
- 夹具没有 `package.json` 和 `node_modules`；jest、vitest 均不可用 → ⚠️ 未检测到测试框架
- 备选方案：使用 Node v24.15.0 内置的 `node:test` 和 `node:assert/strict`，并沿用 `describe`/`it` 结构
- 测试文件只写入 `/tmp/ps-eval-run19-tester/`，没有改动 `project/src`；源码 mtime 仍为 14:10:32，project 下仍只有 1 个文件

**Execution** — `node --test --test-reporter=spec amount-ac.test.mjs`
结果：**10 tests / 6 pass / 4 fail / 0 skip**

| AC | 预期 | 实际 | 结论 |
|---|---|---|---|
| `'.5'` → `'0.5'` | `0.5` | `.5` | **[RED 证据]** |
| `'-.5'`（同一规则的负数分支） | `-0.5` | `-.5` | [RED 证据] |
| `'.75'`（多位小数） | `0.75` | `.75` | [RED 证据] |
| `'.567'`（截断至 2 位） | `0.56` | `.56` | [RED 证据] |

边界 6 条全部通过：`null`、`undefined`、`''` 均返回 `''`，`'0.5'` 原样保留，`'007'`→`'7'`，超长数字串不截断。

**根因（只定位、不修复）**：`amount.ts:51` 的补 0 分支条件是 `clean.startsWith('0')`，所以以 `.` 开头的输入永远不会进入该分支，随后 `amount.ts:63` 直接返回 `.5`。缺少“`clean` 以 `.` 开头时在前面补 `0`”的分支；负数的处理路径在 `:37/61`，同样没有补 0。

**Validation**：V1 ✅｜V2 ✅｜V3 ✅｜V4 ✅ 未篡改源码｜V5 ⚠️ 无覆盖率基线｜V6 ✅（4 条 RED、0 条环境错误）
报告已写入 `/tmp/ps-eval-run19-tester/TEST-REPORT-formatAmount.md`。

```js
// /tmp/ps-eval-run19-tester/amount-ac.test.mjs（节选）
import { test, describe } from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '.../project/src/utils/amount.ts'

describe('formatAmount — AC: 小数必须以 0 开头', () => {
  test('AC: ".5" -> "0.5"', () => assert.equal(formatAmount('.5'), '0.5'))
  test('同族: "-.5" -> "-0.5"', () => assert.equal(formatAmount('-.5'), '-0.5'))
  test('同族: ".75" -> "0.75"', () => assert.equal(formatAmount('.75'), '0.75'))
  test('同族: ".567" -> "0.56"', () => assert.equal(formatAmount('.567'), '0.56'))
})

describe('formatAmount — 边界/异常', () => {
  test('null -> ""', () => assert.equal(formatAmount(null), ''))
  test('undefined -> ""', () => assert.equal(formatAmount(undefined), ''))
  test('"" -> ""', () => assert.equal(formatAmount(''), ''))
  test('"0.5" 原样', () => assert.equal(formatAmount('0.5'), '0.5'))
  test('"007" -> "7"', () => assert.equal(formatAmount('007'), '7'))
  test('超长输入不截断', () =>
    assert.equal(formatAmount('12345678901234567890'), '12345678901234567890'))
})
```

修复后重跑同一命令，4 条 RED 用例应转绿，其余 6 条须保持通过。
