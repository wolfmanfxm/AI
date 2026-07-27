# Trigger Words

## 分析模式 (Phase 1 Discover)

### 中文触发词（精确匹配优先）
- 分析项目 / 分析这个项目 / 帮我分析下项目
- 代码分析 / 项目代码分析
- 项目审计 / 代码审计
- 扫描项目 / 梳理项目结构
- 梳理组件 / 梳理组件库
- 刷新项目知识 / 更新项目知识
- 项目规范 / 编码规范 → **仅当上下文含"项目/代码/扫描"时触发**，否则路由到用户指令
- 代码风格 → **仅当上下文含"分析/扫描/提取"时触发**

### English Triggers
- analyze codebase / analyze this project
- scan project / scan codebase
- project audit / code audit
- project refresh / refresh project knowledge
- generate architecture overview

### 排除（不触发本 skill）
以下场景即使出现"分析"也不触发，避免与其他 skill 冲突：
- "分析这个需求" → 产品/规划类 skill
- "分析日志" → 调试类 skill
- "分析性能" → performance-optimization
- "分析这个 bug" → systematic-debugging
- "代码审查" → code-review / project-reviewer
- "安全审查" → security-auditor

## 恢复触发 (Phase 2 Resume)

### 中文触发词
- 继续分析 / 继续上次分析
- 开始分析 → 仅在 `analysis-config.json` 存在且 `status != completed` 时命中
- 确认配置 → 仅在 `manifest status = confirmed` 时命中

### English Triggers
- resume analysis / continue analysis
- start analysis → 同上条件

## 开发前检查模式

### 中文触发词
- 新增组件 / 创建组件 / 写一个组件
- 创建页面 / 新增页面 / 写一个页面
- 开发前检查
- 写一个 XX → **仅当 `.project-knowledge/` 已存在时触发**

### English Triggers
- pre-dev check
- before coding
- create component / add page → 同上条件
