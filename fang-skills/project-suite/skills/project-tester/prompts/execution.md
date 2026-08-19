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
- 断言失败 → **不修改被测代码**，记录到报告 `[潜在Bug]`

## Exit

- 所有测试文件写入
- 执行结果已记录（通过/失败/跳过）
- 覆盖率数据已采集

## Failure

| Condition | Action |
|-----------|--------|
| 语法/类型/配置错误 | 修正 import 路径、mock 配置、类型引用 → 重试最多 2 次 |
| 断言失败（= 发现潜在 bug） | **不修改源码**，记录到 TEST-REPORT.md：被测代码行号 + 预期 vs 实际 |
| 已有同名测试文件 | 检查是否同一测试目标 → 追加用例 / 重命名 `-extended` 后缀 |
