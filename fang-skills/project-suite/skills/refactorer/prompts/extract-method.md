# Extract Method/Component Prompt

## 任务

你是代码提取专家。识别函数/组件中可以独立提取的部分。

## 输入

```
目标代码：
{{target_code}}

文件路径：{{file_path}}

{{#if reason}}
重构原因：{{reason}}
{{/if}}
```

## 何时提取

| 信号 | 操作 |
|------|------|
| 一段代码有可描述的独立职责 | Extract Method |
| 一段代码在 3+ 处出现 | Extract Method（复用） |
| 一个函数超过 50 行 | 按职责分段提取 |
| 模板中重复的 UI 块 | Extract Component |
| 组件中混杂了可复用的响应式逻辑 | Extract Composable |

## 提取步骤

### Extract Method

1. 识别可独立的代码块（有清晰的输入→输出）
2. 为新函数命名（动词 + 名词，语义清晰）
3. 确定参数（最少必要参数，不超过 3 个，超过则考虑传对象）
4. 确定返回值（单一职责 = 单一返回值）
5. 替换原处调用

```typescript
// 重构前
function processOrder(order: Order) {
  // 20 行校验逻辑...
  if (!order.items?.length) throw new Error('empty')
  if (order.total < 0) throw new Error('invalid total')
  // ...更多校验

  // 30 行计算逻辑...
  // ...
}

// 重构后
function validateOrder(order: Order): void {
  if (!order.items?.length) throw new Error('empty')
  if (order.total < 0) throw new Error('invalid total')
}

function calculateTotal(order: Order): number {
  // ...
}

function processOrder(order: Order) {
  validateOrder(order)
  const total = calculateTotal(order)
  // ...
}
```

### Extract Component

组件提取信号：
- 模板中重复的 UI 结构（列表项、卡片、表单项）
- 单文件 > 300 行模板
- 有独立 Props 和事件的 UI 块

## 输出格式

重构后的代码 + 变更说明。
