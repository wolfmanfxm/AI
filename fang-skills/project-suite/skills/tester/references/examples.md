# Examples — Tester

> 真实测试示例。

---

## 示例 1：工具函数单元测试

### 输入

> "给 `src/utils/validate.ts` 的 `isValidPhone` 写测试，函数签名为 `(phone: string) => boolean`"

### 输出

```typescript
import { describe, it, expect } from 'vitest'
import { isValidPhone } from './validate'

describe('isValidPhone', () => {
  it('应该在传入 11 位手机号时返回 true', () => {
    expect(isValidPhone('13800138000')).toBe(true)
  })

  it('应该在传入空字符串时返回 false', () => {
    expect(isValidPhone('')).toBe(false)
  })

  it('应该在传入少于 11 位时返回 false', () => {
    expect(isValidPhone('1380013800')).toBe(false)
  })

  it('应该在传入包含字母时返回 false', () => {
    expect(isValidPhone('1380013800a')).toBe(false)
  })

  it('应该在传入非 1 开头时返回 false', () => {
    expect(isValidPhone('23800138000')).toBe(false)
  })
})
```

---

## 示例 2：组件测试

### 输入

> "给 `StatusTag.vue` 写测试，Props: `status: 'pending' | 'processing' | 'done'`，不同状态显示不同颜色和文字"

### 输出

```typescript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import StatusTag from './StatusTag.vue'

describe('StatusTag', () => {
  it('应该在 status 为 pending 时显示"待处理"', () => {
    const wrapper = mount(StatusTag, { props: { status: 'pending' } })
    expect(wrapper.text()).toContain('待处理')
  })

  it('应该在 status 为 done 时显示绿色', () => {
    const wrapper = mount(StatusTag, { props: { status: 'done' } })
    expect(wrapper.classes()).toContain('status-tag--success')
  })
})
```
