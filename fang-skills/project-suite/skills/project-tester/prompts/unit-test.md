# Unit Test Prompt

## 任务

你是单元测试专家。为指定函数/方法生成测试用例。

## 前置

1. 读被测函数的完整代码
2. 识别：参数类型、返回值类型、分支条件、依赖调用
3. 确认 mock 对象（参考 [mock-strategy](../references/mock-strategy.md)）

## 输入

```
被测函数：{{target_function}}
文件路径：{{file_path}}

{{#if dependencies}}
依赖（需要 mock）：
{{dependencies}}
{{/if}}

{{#if examples}}
现有测试风格参考：
{{examples}}
{{/if}}
```

## 测试生成

### 覆盖矩阵

对每个被测函数，列出：

| 场景 | 输入 | 预期输出 | 优先级 |
|------|------|---------|--------|
| 正常 | ... | ... | P0 |
| 空值 | null/undefined/[] | ... | P0 |
| 边界 | 0/-1/max/min | ... | P0 |
| 异常 | 无效参数 | throw/error | P1 |
| 类型边界 | 超大数/超长字符串 | ... | P2 |

### 断言目标行为，不是现状行为

有 AC / 需求时，expected 必须来自**目标行为**，不能照着当前实现的返回值写。
照现状写等于把缺陷固化成规格——测试永远是绿的，Bug 永远不会被发现。

| 场景 | ❌ 照现状写（绿但错） | ✅ 照目标写（RED） |
|------|---------------------|-------------------|
| AC：金额为负应抛错，当前实现返回 `-¥50.00` | `expect(formatPrice(-50)).toBe('-¥50.00')` | `expect(() => formatPrice(-50)).toThrow()` |

照目标写出 RED 时，按 [execution.md](execution.md) 的「失败的两种含义」记 `[RED 证据]`，不记 `[潜在Bug]`。

### 断言风格

用项目现有断言库的风格：
- vitest/jest: `expect(x).toBe(y)` / `expect(fn).toThrow()`
- assert: `assert.equal(x, y)` / `assert.throws(fn)`

### 命名规范

```
describe('模块/文件名', () => {
  describe('函数名', () => {
    it('应该在[场景]时[行为]', () => {
      // Given-When-Then
    })
  })
})
```

## 示例

### 输入

> 测试 `src/utils/formatPrice.ts` 的 `formatPrice` 函数，将数字格式化为¥金额字符串

### 输出

```typescript
import { describe, it, expect } from 'vitest'
import { formatPrice } from './formatPrice'

describe('formatPrice', () => {
  it('应该在传入整数时返回带两位小数的金额', () => {
    expect(formatPrice(100)).toBe('¥100.00')
  })

  it('应该在传入小数时保留两位小数', () => {
    expect(formatPrice(99.99)).toBe('¥99.99')
  })

  it('应该在传入 0 时返回 ¥0.00', () => {
    expect(formatPrice(0)).toBe('¥0.00')
  })

  it('应该在传入负数时返回带负号的金额', () => {
    expect(formatPrice(-50)).toBe('-¥50.00')
  })

  it('应该在传入 NaN 时抛出错误', () => {
    expect(() => formatPrice(NaN)).toThrow('Invalid price')
  })
})
```
