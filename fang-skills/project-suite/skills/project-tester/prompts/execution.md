# Execution — Tester

> @template: execution

## Actions

### 1. 读被测代码：`@adapter:filesystem.read <target>`
- 理解函数签名、输入类型、输出类型
- 识别边界条件（null/undefined/空数组/空字符串/超长输入）
- 识别依赖（API/Store/其他模块）→ 准备 mock

### 2. 生成测试用例
- 对照 AC 逐条生成，至少 1 用例/AC
- 格式：`describe('模块名', () => { it('应该...', () => { ... }) })` 或 Given-When-Then
- 遵循项目测试框架的 API 风格

### 3. 覆盖清单
- ✅ Happy path（正常输入 → 预期输出）
- ✅ 边界（null / undefined / 空数组 / 空字符串 / 超长输入）
- ✅ 异常（网络错误 / timeout / 权限不足 / 数据格式错误）

### 4. 尝试执行
- `npx vitest run <test-file>` 或等价命令
- 语法/配置错误 → 修正（最多 2 次）
- 断言失败 → **不修改被测代码**，先判失败性质（见下），再记录

### 失败的两种含义（不要一律记 `[潜在Bug]`）

| 失败形态 | 含义 | 记录为 |
|---------|------|--------|
| 用例断言的是 AC 要求的目标行为，实现还没做到 | **RED 证据**：证明当前实现确实不满足这条 AC，可直接作为修复输入 | `[RED 证据]` + 断言 vs 实际 + 对应 AC |
| 实现看起来满足 AC，但边界/异常路径崩了 | 真实缺陷，根因未知 | `[潜在Bug]` + 行号 + 预期 vs 实际，按 [systematic-debugging](../../../shared/primitives/systematic-debugging.md) 定位 |
| import / mock / 框架版本等环境错误 | **不是有效 RED** | 修正后重跑，不计入失败统计 |

> RED 证据 ≠ 测试通过，也 ≠ Bug 报告：它是「目标行为未满足」的可复现证明。
> 下游修复后，tester 用**同一条用例**复核转绿；仍然失败才是没修好。
> 证据：eval ledger · `tester-red-classification`。

## Exit

- 所有测试文件写入
- 执行结果已记录（通过/失败/跳过）
- 覆盖率数据已采集

## Failure

| Condition | Action |
|-----------|--------|
| 语法/类型/配置错误 | 修正 import 路径、mock 配置、类型引用 → 重试最多 2 次（不算失败） |
| 断言失败（目标行为未满足） | 标 `[RED 证据]`：不改源码，记录对应 AC + 预期 vs 实际；修复后用同一条用例复核 |
| 断言失败（预期外 / 边界崩溃） | 标 `[潜在Bug]`：不改源码，记录 `TEST-REPORT-<task_id>.md` 被测代码行号 + 预期 vs 实际 |
| 已有同名测试文件 | 检查是否同一测试目标 → 追加用例 / 重命名 `-extended` 后缀 |
