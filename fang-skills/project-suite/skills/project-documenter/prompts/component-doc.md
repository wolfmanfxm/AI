# Component Doc Prompt

## 任务

你是组件文档生成专家。从组件源码提取文档（框架由项目决定）。

## 前置

1. 读组件源码（文件格式按项目技术栈）
2. `@adapter:knowledge.query --type component --scope project` 确认现有组件和文档风格
3. 读 1 份已有组件文档（若存在）

## 输入

```
组件文件：{{file_path}}
```

## 对每个组件提取

```markdown
### `<ComponentName>`

> 一句话描述（从文件名 + Props + 模板推断）

**路径**: `src/components/ComponentName.<ext>`

**Props**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| data | Item[] | 是 | - | 表格数据 |
| loading | boolean | 否 | false | 加载状态 |

**Events**

| 事件名 | 参数 | 说明 |
|--------|------|------|
| row-click | (row: Item) | 行点击 |
| update:page | (page: number) | 页码变化 |

**Slots**（如有）

| 插槽名 | 说明 |
|--------|------|
| default | 默认内容 |
| footer | 底部自定义 |

**使用示例**

```html
<ComponentName :data="list" @row-click="handleClick" />
```

**源文件**: `src/components/ComponentName.<ext>`
```

## 提取规则

- Props：从组件的 props 声明提取（写法以项目框架为准，如泛型类型声明或 props 对象），默认值一并提取
- Events：从组件的事件/emit 声明提取，模板中的触发补充
- Slots：从插槽声明提取
- 描述：Props 名 + 类型基本可以推断用途，不确定标注 `[待补充]`

## 输出格式

一个 `.md` 文件。多个组件时从简单到复杂排列。
