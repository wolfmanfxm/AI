# Coding Guidelines

> 生成日期：{{date}} | 项目：{{project}} | 版本：{{version}}

## Framework（检测到的框架名，如 Vue / React / Angular）

### 组件写法
- **代码事实**：从实际代码统计的风格及占比
- **示例**：实际项目的典型组件结构

### 组件通信
- **父子**：实际使用的通信方式
- **跨层级**：provide/inject、Context 等
- **全局**：状态管理库、事件总线等
- **示例**：每种模式的实际代码片段

## Language（检测到的语言，如 TypeScript / JavaScript）

### 类型定义位置
- 内联组件文件：N 处
- 独立类型文件：N 处
- 全局声明文件：N 处

### 类型工具使用
- interface vs type 的使用偏好
- 泛型使用模式
- any/unknown 的使用情况

## UI Library（检测到的 UI 库）

### 使用方式
- 按需导入 vs 全局注册
- 自定义命名空间（如有）

### 样式覆盖
- 覆盖方式：`:deep()` / CSS Module / 全局样式
- 主题定制方式

## Naming

### 文件命名
- 组件文件的实际命名风格（如 PascalCase、kebab-case）
- 工具文件的命名风格

### 变量命名
- 响应式变量 / state 的命名约定
- 常量的命名约定
- 函数的命名约定

### API 函数命名
- 命名风格及占比（如 Swagger 生成 vs 手写）

## Imports

### 排序约定
实际项目的 import 排序模式。

### 路径别名
项目中定义的路径别名（从 `tsconfig.json` 或 `vite.config` 等读取）。

## Error Handling

### 请求错误
- 全局拦截器处理方式
- 局部错误处理模式

### 组件错误
- ErrorBoundary / onErrorCaptured 使用情况

## Async Patterns

### 数据请求
- async/await vs .then() 使用比例
- Loading 状态管理模式
- 并发请求处理方式

## Best Practices

基于代码分析总结的最佳实践清单，每条标注来源文件和实际代码示例。
