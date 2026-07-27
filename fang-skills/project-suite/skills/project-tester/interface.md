# Interface: project-tester

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Test** — `.test.ts / .spec.ts` + `reports/TEST-REPORT.md`

## Consumes
- 🔴 **Code**（被测代码，缺失则 BLOCKED）
- 🟡 **KnowledgeBase**（`.project-knowledge/patterns/`，缺失则 DEGRADED）

## Guarantees
- 自动检测测试框架（jest/vitest/mocha）
- Given-When-Then / describe-it-expect 结构
- 覆盖 happy path + 边界（null/空/超长/并发）+ 异常
- 测试失败记录原因，不修改被测代码

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 被测代码不可读 | BLOCKED | 拒绝执行 |
| 无测试框架检测到 | DEGRADED | 默认 jest 风格 |
| 测试执行失败 | DEGRADED | 记录失败原因到报告，不修改代码 |
