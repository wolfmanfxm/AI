# Examples — Refactorer

> 真实重构示例。

---

## 示例 1：Extract Method

### 输入

> "`src/views/order/create.vue` 的 `handleSubmit` 函数 80 行，校验+提交+成功+错误全在一起，帮我提取"

### 重构

```typescript
// 重构前
async function handleSubmit() {
  // 15 行校验
  if (!formData.productId) { ElMessage.warning('请选择商品'); return }
  if (formData.quantity < 1) { ElMessage.warning('数量至少为1'); return }
  // ...

  loading.value = true
  try {
    // 10 行数据组装
    const params = { ... }
    await createOrder(params)

    ElMessage.success('创建成功')
    emit('success')
  } catch (e) {
    ElMessage.error('创建失败')
  } finally {
    loading.value = false
  }
}

// 重构后
function validateForm(data: typeof formData): boolean {
  if (!data.productId) { ElMessage.warning('请选择商品'); return false }
  if (data.quantity < 1) { ElMessage.warning('数量至少为1'); return false }
  return true
}

function buildOrderParams(data: typeof formData): CreateOrderParams {
  return { productId: data.productId, quantity: data.quantity }
}

async function handleSubmit() {
  if (!validateForm(formData)) return

  loading.value = true
  try {
    await createOrder(buildOrderParams(formData))
    ElMessage.success('创建成功')
    emit('success')
  } catch {
    ElMessage.error('创建失败')
  } finally {
    loading.value = false
  }
}
```

### 改善

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| handleSubmit 行数 | 82 | 15 |
| 可测试性 | 无法单独测试校验逻辑 | validateForm 可独立测试 |

---

## 示例 2：简化嵌套

### 输入

> "`getUserLevel` 嵌套了 4 层 if，帮我简化"

### 重构

```typescript
// 重构前
function getUserLevel(user: User | null): string {
  if (user) {
    if (user.isActive) {
      if (user.points > 10000) {
        return 'gold'
      } else {
        if (user.points > 1000) {
          return 'silver'
        } else {
          return 'bronze'
        }
      }
    } else {
      return 'inactive'
    }
  } else {
    return 'guest'
  }
}

// 重构后
function getUserLevel(user: User | null): string {
  if (!user) return 'guest'
  if (!user.isActive) return 'inactive'
  if (user.points > 10000) return 'gold'
  if (user.points > 1000) return 'silver'
  return 'bronze'
}
```

### 改善

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| 圈复杂度 | 6 | 6（不变，但可读性显著提升） |
| 最大嵌套 | 4 层 | 0 层（Guard Clause 完全扁平化） |
