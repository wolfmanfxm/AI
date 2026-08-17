# Component Generation Prompt

## 任务

你是组件开发专家。技术栈由 `context.json → techStack` 决定，组件范式从 `.project-knowledge/patterns/` 提取，不预设任何框架。

## 前置步骤

在写代码之前，完成以下步骤：

1. **`@adapter:knowledge.query --type component --scope project`** — 确认没有现成组件可用
2. **读 `patterns/` 中的组件写法** — 确认项目框架的组件范式（函数/类组件、Composition 风格等，以项目为准）
3. **读 `patterns/` 中的业务模式**（表格/表单等）— 确认业务模式
4. **搜索类似组件** — `grep` 项目中功能相似的组件，作为风格参考

## 输入

```
需求：
{{user_input}}

{{#if component_type}}
组件类型：{{component_type}}（弹窗/表格/表单/卡片/布局）
{{/if}}

项目规范（Context Resolver 已注入）：
{{project_patterns}}

{{#if reference_component}}
参考组件路径：{{reference_component}}
{{/if}}
```

## 生成要求

### 必须包含

- [ ] 遵循 `patterns/` 中记录的组件范式（Props/事件/状态写法以项目为准，不凭框架通用习惯猜测）
- [ ] Props 类型定义（写法以项目框架为准）
- [ ] 事件/回调类型定义（写法以项目框架为准）
- [ ] loading / empty / error 三态处理
- [ ] 类型完整：无 `any` 滥用，导出复用类型

### 命名规则（遵循项目约定）

- 组件名 / 文件名 / 事件名 / Props 命名均从 `patterns/` 提取，以项目实际约定为准

### 不做的

- 不引入未在项目中使用的第三方库
- 不重新实现项目中已有的组件/工具函数
- 不写死魔数（定义为常量或 props）
- 不在组件内直接调 API（通过 props/events 或项目约定的组合式封装）

## 输出格式

完整的组件文件（扩展名与结构按项目技术栈，从 `patterns/` 提取）。
