# Workflow: greenfield

> ⚠️ **v0.7.0: 此 .md 工作流已废弃。** 保留为历史参考。
> 当前工作流模板：`runtime/workflows/full-sdlc.yaml`（YAML 格式，User-as-Dispatcher）
> 编排协议：`runtime/protocols/orchestration.md`

## 历史（v0.4.0 自动流水线，已废弃）

> 全新项目。从零开始的完整 SDLC。

## 触发

- 用户说"新建项目""从零开始""初始化项目"
- 无现有 `.project-knowledge/`

## 流程

```
analyzer -> planner -> architect -> generator -> tester -> reviewer
  |           |           |             |           |          |
  v           v           v             v           v          v
Knowledge   Plan    Architecture     Code       Test      Review
  |           |           |             |           |          |
  +-----------+-----------+-------------+-----------+----------+
                              |
                     documenter -> releaser
                         |            |
                         v            v
                    Documentation  Release
```

## 与 feature 的区别

| | feature | greenfield |
|---|---------|-----------|
| analyzer | 可选（已有知识库） | 必须（首次建立） |
| planner | 需求拆解 | 需求拆解 + 技术栈确认 |
| architect | 可选 | 必须（无现有架构可参考） |
| documenter | 可选 | 必须（建立文档体系） |
| releaser | 可选 | 必须（首次发布） |

## 各步详情

| Step | Skill | 输入 | 输出 |
|------|-------|------|------|
| 1 | analyzer | 源码目录 | KnowledgeBase + Context |
| 2 | planner | KnowledgeBase + 项目需求 | Plan（全量任务） |
| 3 | architect | KnowledgeBase + Plan | Architecture（整体架构） |
| 4 | generator | All of above | Code（核心模块） |
| 5 | tester | Code | Test |
| 6 | reviewer | Code + Plan | Review |
| 7 | documenter | Code + Review | Documentation |
| 8 | releaser | Documentation + Review + Test | Release |
