# Component Test Prompt

## 任务

你是组件测试专家。测试框架由项目决定（从现有测试提取），为指定组件生成测试。

## 前置

1. 读组件的 Props、Emits、Slots 定义
2. 读组件模板，识别关键交互元素（按钮、输入框、条件渲染）
3. 确认测试工具与框架（从项目现有测试提取，如 jest / vitest / mocha 等）
4. 确认项目中组件的测试惯例（mount 方式、stub 策略）

## 输入

```
组件：{{component_name}}
文件路径：{{file_path}}

{{#if props}}
Props 类型：
{{props}}
{{/if}}

{{#if existing_tests}}
现有组件测试风格参考：
{{existing_tests}}
{{/if}}
```

## 必须覆盖

| 测试项 | 说明 |
|--------|------|
| **渲染** | 组件正常挂载、关键 DOM 元素存在 |
| **Props** | 传入不同 Props，渲染结果正确 |
| **事件** | 触发交互，emit 正确的事件和数据 |
| **条件渲染** | v-if/v-show 在不同状态下正确切换 |
| **Slot** | 插槽内容正确渲染 |
| **异步** | loading → success → error 状态流转 |

## 示例

> 以下示例基于某前端框架的组件测试工具，实际按项目测试框架与惯例生成。

```typescript
import { describe, it, expect, vi } from '<test-runner>'
import { mount } from '<component-test-utils>'
import SearchForm from './SearchForm'

describe('SearchForm', () => {
  it('应该在挂载时渲染搜索输入框和按钮', () => {
    const wrapper = mount(SearchForm)
    expect(wrapper.find('input').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('应该在点击搜索时 emit search 事件', async () => {
    const wrapper = mount(SearchForm)
    await wrapper.find('input').setValue('测试关键词')
    await wrapper.find('button[type="submit"]').trigger('click')
    expect(wrapper.emitted('search')).toBeTruthy()
    expect(wrapper.emitted('search')![0]).toEqual([{ keyword: '测试关键词' }])
  })

  it('应该在传入 initialValue prop 时预填输入框', () => {
    const wrapper = mount(SearchForm, {
      props: { initialValue: '预填词' }
    })
    expect(wrapper.find('input').element.value).toBe('预填词')
  })
})
```
