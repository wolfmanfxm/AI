# Trigger Words — Refactorer

## 中文触发词

### 提取
- 提取函数、提取方法、抽成函数
- 提取组件、抽组件
- 提取公共逻辑、消除重复

### 简化
- 简化代码、简化逻辑、简化条件
- 优化这段代码（改结构不改行为）
- 太多 if-else、嵌套太深

### 命名
- 重命名、改个名字、语义化命名

### 清理
- 删死代码、移除未使用的
- 拆分模块、文件太大、这个文件太长了

## English Triggers

- refactor, clean up, extract method
- simplify, reduce complexity, reduce nesting
- rename, remove dead code, split module
- extract component, extract composable

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "优化这段代码" | refactorer vs generator | 改结构不改行为 → refactorer；加功能/改行为 → generator |
| "改一下这个函数" | refactorer vs generator | 问清楚：改结构还是改行为？ |
| "这段代码太复杂了" | refactorer | 直接路由 |
