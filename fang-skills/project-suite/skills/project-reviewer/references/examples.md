# Examples — Reviewer

> 真实审查示例。

---

## 示例 1：标准 CRUD 页面审查

### 输入

审查 `src/views/order/list.vue`，一个订单列表页。

### 输出（REVIEW.md 摘要）

#### 🔴 BLOCKER

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 1 | 安全性 | `list.vue:78` | `v-html="item.remark"` 直接渲染用户输入的备注，存在 XSS 风险 | 使用 `{{ item.remark }}` 文本插值，或对内容做 DOMPurify 处理 |

#### 🟠 HIGH

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 2 | 正确性 | `list.vue:35` | `watch(filter, fetchData)` 在筛选条件快速切换时可能竞态：旧请求晚返回覆盖新数据 | 使用 requestId 校验或 abortController |
| 3 | 性能 | `list.vue:42` | `computed` 中调用 `JSON.parse(JSON.stringify(data))` 做深拷贝，每次 data 变化都重新执行 | 如果只是防修改，在赋值时做深拷贝而不是 computed 中 |

#### 🟡 MEDIUM

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 4 | 可读性 | `list.vue:120` | 函数 `handleSubmit` 超过 80 行，包含校验+提交+成功处理+错误处理 | 拆分为 `validate` `submit` `handleSuccess` `handleError` |

#### 🔵 PRAISE

| # | 文件:行 | 做得好的地方 |
|---|---------|-------------|
| 1 | `list.vue:15` | `useTableSelection` composable 封装多选逻辑，复用性好 |
| 2 | `list.vue:88` | 删除操作加了 `ElMessageBox.confirm` 二次确认 |

---

## 示例 2：API 模块审查

### 输入

审查 `src/api/payment.ts`

### 输出（REVIEW.md 摘要）

#### 🟠 HIGH

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 1 | 正确性 | `payment.ts:22` | `submitPayment` 的金额参数类型是 `string`，没有校验是否为合法数字 | 添加 `isNaN(parseFloat(amount))` 校验或改为 `number` 类型 |

#### 🟡 MEDIUM

| # | 轴 | 文件:行 | 问题 | 建议 |
|---|-----|---------|------|------|
| 2 | 可读性 | `payment.ts:8` | 接口 `PaymentQuery` 的 3 个可选字段都注释为"必填" | 修改注释或改为 `required` |
