# Simplify Logic Prompt

## 任务

你是逻辑简化专家。识别可以简化的条件表达式、循环和重复代码。

## 输入

```
目标代码：
{{target_code}}

{{#if complexity}}
复杂度指标（如有）：
{{complexity}}
{{/if}}
```

## 简化手法

### 1. Guard Clause（卫语句）— 替代深层嵌套

```typescript
// 重构前 — 嵌套 3 层
function getDiscount(user: User): number {
  if (user) {
    if (user.isVip) {
      if (user.years > 5) {
        return 0.3
      } else {
        return 0.2
      }
    } else {
      return 0
    }
  } else {
    return 0
  }
}

// 重构后 — 扁平化
function getDiscount(user: User | null): number {
  if (!user) return 0
  if (!user.isVip) return 0
  if (user.years > 5) return 0.3
  return 0.2
}
```

### 2. 提前返回 — 减少 else

```typescript
// 重构前
function foo(x: number) {
  if (x > 0) {
    return processPositive(x)
  } else {
    return processNonPositive(x)
  }
}

// 重构后
function foo(x: number) {
  if (x > 0) return processPositive(x)
  return processNonPositive(x)
}
```

### 3. 三元替代简单 if-else

```typescript
// 重构前
let label: string
if (status === 'done') {
  label = '已完成'
} else {
  label = '进行中'
}

// 重构后
const label = status === 'done' ? '已完成' : '进行中'
```

### 4. 对象映射替代 switch

```typescript
// 重构前
function getStatusText(status: string): string {
  switch (status) {
    case 'pending': return '待处理'
    case 'processing': return '处理中'
    case 'done': return '已完成'
    default: return '未知'
  }
}

// 重构后
const STATUS_MAP: Record<string, string> = {
  pending: '待处理',
  processing: '处理中',
  done: '已完成',
}
const getStatusText = (s: string) => STATUS_MAP[s] ?? '未知'
```

### 5. 可选链替代多层判空

```typescript
// 重构前
const city = user && user.address && user.address.city

// 重构后
const city = user?.address?.city
```

## 警告

不要过度简化。以下情况保持原样更好：
- 条件逻辑本来就该复杂（业务规则复杂）
- 可读性比简洁更重要（switch > 对象映射，当 case < 4 个时）
