# Trigger Words

## 分析模式 (Phase 1 Discover)

### 中文触发词
- 分析项目
- 代码分析
- 项目审计
- 发现模式
- 梳理组件
- 更新项目知识
- 项目规范
- 编码规范
- 代码风格
- 刷新项目知识
- 项目文档生成

### English Triggers
- project refresh、scan project、generate architecture、analyze codebase

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "分析这个项目" vs "审计这个项目" | analyzer vs security-auditor | 代码结构和模式分析 → analyzer；安全漏洞扫描 → 安全审查 |
| "更新项目知识" vs "写项目文档" | analyzer vs documenter | 自动分析生成代码结构文档 → analyzer；手写/更新 README/API 文档 → documenter |
| "开发前检查" vs "直接开发" | analyzer vs generator | 需要知道项目用什么组件/怎么写 → analyzer 开发前检查；已经清楚直接写代码 → generator

## 恢复触发 (Phase 2 Resume)

### 中文触发词
- 继续分析
- 开始分析
- 确认配置

### English Triggers
- resume
- analyze now
- start analysis

## 开发前检查模式

### 中文触发词
- 新增组件
- 创建页面
- 写一个 XX
- 实现 XX 功能
- 开发前检查

### English Triggers
- pre-dev check
- before coding
