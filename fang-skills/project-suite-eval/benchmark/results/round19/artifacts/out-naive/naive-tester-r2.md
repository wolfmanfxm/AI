已为 AC 编写并执行单元测试，结果显示当前实现不满足 AC（测试红）。

- 测试文件：/tmp/ps-eval-run19-tester/amount.test.mjs；直接 import 真实源文件 project/src/utils/amount.ts，由 Node v24 原生类型擦除执行，未依赖 node_modules，未改动 project/src。
- 执行命令：`node --test amount.test.mjs`；结果：tests 1 / pass 0 / fail 1。
- 失败详情：`'.5' !== '0.5'`（Expected values to be strictly equal，actual '.5'）。

```js
import test from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '/Users/fangxiangming/.cache/ps-eval/round19/tester/project/src/utils/amount.ts'

test('formatAmount: 输入 ".5" 应返回 "0.5"（小数必须以 0 开头）', () => {
  assert.equal(formatAmount('.5'), '0.5')
})
```

根因定位：formatAmount 只做了「去多余前导 0」和「补负号」，没有「小数以点开头时补 0」的分支；'.5' 经清洗后仍为 '.5'，既不匹配 `startsWith('0')` 也无补零逻辑，直接返回。探测同类输入确认影响面一致：'.'→'.'、'.50'→'.50'、'-.5'→'-.5'、'-.50'→'-.50'；'0.5'、'1.5' 正常。修复方向：在返回前对非空 clean 判断 `/^\./` 补 '0'，对 `/^-\./` 补 '-0'（需同时考虑 '-'、'-.'、'-0.' 等输入态豁免，避免破坏受控输入体验），但本次仅只读评估未改源码。

污染自检：未读取 SKILL.md/project-suite（是）
