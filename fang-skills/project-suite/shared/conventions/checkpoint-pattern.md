# CHECKPOINT 确认模式

所有 project-suite skill 在需要用户确认的步骤使用此模式。

## 格式

- **header**: 2-4 字中文标签
- **options**: 2-4 个，第一个为推荐（标注「推荐」）
- **multiSelect**: 始终 false

## 模板

```typescript
AskUserQuestion({
  questions: [{
    question: "<一句话问题>",
    header: "<2-4字标签>",
    options: [
      { label: "✅ <操作>（推荐）", description: "<说明>" },
      { label: "🔧 调整", description: "<说明>" },
      { label: "❌ 取消", description: "不做任何操作" }
    ],
    multiSelect: false
  }]
})
```
