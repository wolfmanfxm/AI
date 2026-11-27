测试已写入 `/tmp/ps-eval-run19-tester/formatAmount.ac.test.mjs` 并执行。夹具无 node_modules 未阻塞：Node v24.15.0 原生支持 .ts 类型剥离，用 `node --test` 直接 import 被测原文件，未产生任何副本、未改动 project/src。

结果：测试失败（符合预期）。实际输出 `'.5'`，期望 `'0.5'`。根因：实现只在 `clean.startsWith('0')` 时处理前导零，字符串以 `.` 开头时没有任何补零分支；负数 `-.5` 在补回负号后同样得到 `-.5`。测试准确暴露该缺陷。

```js
import test from 'node:test'
import assert from 'node:assert/strict'
import { formatAmount } from '/Users/fangxiangming/.cache/ps-eval/round19/tester/project/src/utils/amount.ts'

test("AC: formatAmount('.5') 应返回 '0.5'（小数必须以 0 开头）", () => {
  const actual = formatAmount('.5')
  assert.equal(actual, '0.5', `期望 '0.5'，实际 '${actual}'`)
})
```

执行命令：`node --test /tmp/ps-eval-run19-tester/formatAmount.ac.test.mjs` → 1 fail，`'.5' !== '0.5'`。

污染自检：未读取 SKILL.md/project-suite（是）
