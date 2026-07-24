# Coding Style Analysis

## Goal
从现有代码中提取实际的编码规范，不推荐理想化方案。

## Context
编码规范取决于项目框架和语言，先读 architecture/overview.md 了解技术栈。

## Evidence
- 组件文件（`.vue` / `.tsx`）
- API 目录
- 类型定义文件
- Import 语句
- 错误处理代码
- Hooks/Composables 目录

## Analysis
1. 统计不同组件写法的占比（script setup vs Options API、函数组件 vs Class）
2. 统计 interface vs type 偏好、any 使用量、泛型模式
3. 分类 API 命名风格（Swagger 生成 vs 手写），计算占比
4. 抽样观察 import 排序规律，从构建配置读取路径别名
5. 定位 HTTP 拦截器，统计 try/catch、async/await、.then() 使用量
6. 按职责分类 hooks/composables（权限、数据请求、UI状态、工具函数）

## Output
`patterns/` 下按需创建：`vue.md`（或 `react.md`）、`typescript.md`、`naming.md`、`folder.md`
每个结论：1个统计数据 + 1个代码示例 + 标注"代码事实/模式推断"
