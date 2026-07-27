# Mock Strategy — Tester

> 测试中 mock 什么、不 mock 什么、怎么 mock。

## 核心原则

**只 mock 不可控的外部依赖，不 mock 可控的内部逻辑。**

## 该 mock 的

| 类型 | 原因 | 示例 |
|------|------|------|
| HTTP 请求 | 不可控、慢、有副作用 | `vi.mock('@/api/user')` |
| 时间 | 测试结果应确定 | `vi.useFakeTimers()` |
| 随机数 | 测试结果应确定 | `vi.spyOn(Math, 'random')` |
| localStorage | 测试间不应互相影响 | mock `localStorage` API |
| 第三方 SDK | 不可控 | 支付 SDK、地图 SDK |
| 环境变量 | 测试间可能不同 | `vi.mock('@/config', () => ({...}))` |

## 不该 mock 的

| 类型 | 原因 |
|------|------|
| 被测函数内部调用的纯函数 | 应该用真实实现验证结果 |
| 数据转换/格式化函数 | mock 它们等于没测 |
| 项目内部的工具函数 | 复杂度低、无副作用 |
| Vue Router / Pinia | 使用真实实例（createTestingPinia）|

## Mock 反例

```typescript
// ❌ 不要这样：mock 了被测函数内部的工具函数
vi.mock('./formatDate', () => ({ formatDate: vi.fn(() => '2026-01-01') }))
// 这等于假设 formatDate 正确，测试失去了验证两函数协作的意义

// ✅ 正确：只 mock HTTP 请求
vi.mock('@/api/user')
```

## 组件测试中的 Stub vs Mock

| 场景 | 方式 |
|------|------|
| 第三方 UI 库组件（el-button） | 不 stub，用真实组件 |
| 项目内子组件（复杂表单） | shallowMount 或 stub: true |
| 全局注入（路由、状态管理） | 使用测试专用 plugin |
