# Intent Routing

> 用户意图 → skill 路由表。所有 skill 触发通过本路由表决策，不自行拦截。

## 路由规则

路由按优先级匹配，首个命中即为目标 skill：

1. **精确触发词匹配** — 用户消息包含 skill 的显式触发词
2. **上下文路由** — 存在 manifest 且状态非 completed → 续执行
3. **语义路由** — 用户意图与 skill 描述最匹配（由 LLM 判断）

## 路由表

### analyzer — 代码分析

**触发场景**：
- 首次接触项目，需要了解代码结构
- 需要生成/刷新项目知识库
- 开发前检查：读取已有分析结果指导编码

**触发词**：
- 中文：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、项目规范、编码规范、刷新项目知识、项目文档生成、继续分析
- English：analyze codebase, scan project, generate architecture, project refresh, resume

**产出**：`.project-knowledge/` + Knowledge Vault

### planner — 任务规划

**触发场景**：
- 拿到需求后需要拆解为可执行任务
- 评估工作量和依赖关系
- 生成开发计划

**触发词**：
- 中文：任务拆解、开发计划、需求分析、排期、估算工作量、分解任务、sprint 规划
- English：break down tasks, plan sprint, estimate effort, create dev plan

**产出**：`PLAN.md`（任务列表、依赖图、预估工时）

### architect — 架构设计

**触发场景**：
- 新技术选型决策
- 模块/服务边界设计
- 数据库 schema 设计
- API 契约设计
- 架构评审

**触发词**：
- 中文：架构设计、技术选型、模块设计、系统设计、数据库设计、API 设计、架构评审
- English：design architecture, tech stack decision, system design, DB schema, API design

**产出**：`ARCHITECTURE.md`（决策记录、模块图、技术选型理由）

### generator — 代码生成

**触发场景**：
- 实现新功能/组件/页面
- 生成 CRUD 样板代码
- 根据设计稿/规划生成代码
- 补充/修改已有代码

**触发词**：
- 中文：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写
- English：implement, create component, build feature, generate code, write a

**产出**：代码文件（`.vue` / `.ts` / `.js` 等）

### tester — 测试

**触发场景**：
- 为新功能写测试
- 补充测试覆盖
- 生成测试用例
- 执行测试并分析结果

**触发词**：
- 中文：写测试、测试用例、单元测试、集成测试、测试覆盖、跑测试
- English：write tests, test cases, unit test, integration test, test coverage

**产出**：测试文件 + 测试报告

### reviewer — 代码审查

**触发场景**：
- PR review
- 代码质量检查
- 安全审查
- 性能审查

**触发词**：
- 中文：代码审查、review、检查代码、审查 PR、代码质量
- English：code review, review PR, check code, security review, audit

**产出**：`REVIEW.md`（分级问题列表 + 修复建议）

### refactorer — 重构

**触发场景**：
- 改善代码结构不改变行为
- 消除技术债务
- 提取公共逻辑
- 简化复杂函数

**触发词**：
- 中文：重构、优化结构、提取公共、简化代码、消除重复
- English：refactor, clean up, extract method, simplify, reduce complexity

**产出**：重构后的代码 + `REFACTOR.md`（变更说明）

### documenter — 文档

**触发场景**：
- 生成/更新 API 文档
- 补全 README
- 写架构决策记录
- 生成 changelog

**触发词**：
- 中文：生成文档、写文档、补文档、API 文档、README、更新文档
- English：generate docs, write documentation, API docs, update README

**产出**：文档文件（`.md`）

### releaser — 发布

**触发场景**：
- 准备发布新版本
- 生成 changelog
- 版本号管理
- 发布前检查清单

**触发词**：
- 中文：发布、上线、发版、release、changelog、版本号、发布检查
- English：release, ship, deploy, changelog, version bump, publish

**产出**：`CHANGELOG.md` + 发布检查清单

## 模糊意图处理

当用户意图同时命中多个 skill（如"帮我实现并测试这个功能"），按工作流链推荐：

```
generator → tester（而非同时触发）
```

先完成上游，再建议下游。不自动级联触发。
